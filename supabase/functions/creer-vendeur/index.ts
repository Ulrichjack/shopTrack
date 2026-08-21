// Crée un compte vendeur et le rattache à une boutique — en une seule
// opération.
//
// Pourquoi côté serveur : créer un compte demande la clé d'administration, qui
// n'a rien à faire dans un téléphone. Quelqu'un qui décompilerait l'APK
// pourrait supprimer n'importe quel compte de n'importe quelle boutique.
//
// Pourquoi une seule opération : depuis l'app, la création réussissait puis le
// rattachement échouait, laissant un compte orphelin — inutilisable, invisible,
// et impossible à supprimer sans accès à la console. Trois s'étaient accumulés
// en une matinée de test. Ici, si le rattachement échoue, le compte est
// supprimé : soit les deux existent, soit aucun.
//
// Déploiement :
//   supabase functions deploy creer-vendeur
//
// `SUPABASE_URL` et `SUPABASE_SERVICE_ROLE_KEY` sont fournis automatiquement
// par Supabase à l'exécution : rien à configurer.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const enTetes = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Content-Type': 'application/json',
};

function reponse(corps: unknown, status = 200) {
  return new Response(JSON.stringify(corps), { status, headers: enTetes });
}

Deno.serve(async (requete) => {
  if (requete.method === 'OPTIONS') {
    return new Response('ok', { headers: enTetes });
  }

  try {
    const { telephone, motDePasse, shopId } = await requete.json();

    if (!telephone || !motDePasse || !shopId) {
      return reponse({ erreur: 'Numéro, mot de passe et boutique requis.' }, 400);
    }
    if (String(motDePasse).length < 6) {
      return reponse(
        { erreur: 'Le mot de passe doit faire au moins 6 caractères.' },
        400,
      );
    }

    const url = Deno.env.get('SUPABASE_URL')!;
    const cleService = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const autorisation = requete.headers.get('Authorization') ?? '';

    // 1. QUI APPELLE — avec SON jeton, donc soumis aux mêmes règles que l'app.
    //    On ne fait jamais confiance à un `shopId` envoyé par un client.
    const clientAppelant = createClient(url, cleService, {
      global: { headers: { Authorization: autorisation } },
      auth: { persistSession: false },
    });

    const { data: appelant } = await clientAppelant.auth.getUser();
    if (!appelant?.user) {
      return reponse({ erreur: 'Connecte-toi pour créer un vendeur.' }, 401);
    }

    // 2. EST-IL PATRON DE CETTE BOUTIQUE ? Un vendeur ne recrute pas.
    const admin = createClient(url, cleService, {
      auth: { persistSession: false },
    });

    const { data: membre } = await admin
      .from('shop_members')
      .select('role')
      .eq('shop_id', shopId)
      .eq('user_id', appelant.user.id)
      .maybeSingle();

    if (membre?.role !== 'owner') {
      return reponse(
        { erreur: 'Seul le patron de cette boutique peut ajouter un vendeur.' },
        403,
      );
    }

    // 3. LE COMPTE EXISTE-T-IL DÉJÀ ? Un employé peut travailler dans deux
    //    boutiques du même patron : on le rattache au lieu de refuser.
    const numero = String(telephone).replace(/\s/g, '').trim();
    const email = `${numero}@shoptrack.cm`;

    const { data: liste } = await admin.auth.admin.listUsers();
    const existant = liste?.users.find((u) => u.email === email);

    let userId: string;
    let creeMaintenant = false;

    if (existant) {
      userId = existant.id;
    } else {
      const { data: cree, error: erreurCreation } =
        await admin.auth.admin.createUser({
          email,
          password: String(motDePasse),
          email_confirm: true,
          user_metadata: { must_change_password: true },
        });

      if (erreurCreation || !cree?.user) {
        return reponse(
          { erreur: erreurCreation?.message ?? 'Compte non créé.' },
          400,
        );
      }
      userId = cree.user.id;
      creeMaintenant = true;
    }

    // 4. LE RATTACHEMENT. S'il échoue et qu'on venait de créer le compte, on
    //    le supprime : pas d'orphelin.
    const { error: erreurLien } = await admin.from('shop_members').insert({
      shop_id: shopId,
      user_id: userId,
      role: 'seller',
    });

    if (erreurLien) {
      if (creeMaintenant) {
        await admin.auth.admin.deleteUser(userId);
      }
      const dejaMembre = erreurLien.code === '23505';
      return reponse(
        {
          erreur: dejaMembre
            ? 'Ce vendeur travaille déjà dans cette boutique.'
            : erreurLien.message,
        },
        dejaMembre ? 409 : 400,
      );
    }

    return reponse({
      userId,
      rattache: true,
      compteExistant: !creeMaintenant,
    });
  } catch (erreur) {
    return reponse({ erreur: `${erreur}` }, 500);
  }
});
