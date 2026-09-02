-- Rembourser une commande ANNULÉE doit être possible.
--
-- Trouvé le 01/09 par la simulation d'une semaine hors ligne, et invisible
-- autrement : le geste marchait parfaitement sur le téléphone. C'est en
-- rejouant la file contre le serveur que le refus est apparu —
--
--   « Impossible d'enregistrer un paiement sur une commande annulée. »
--
-- Or c'est exactement le geste normal. Une cliente annule sa décoration, on
-- lui rend son acompte : annuler d'abord, rembourser ensuite. L'écran le
-- promet même noir sur blanc — « les acomptes déjà encaissés restent à
-- rembourser » — pendant que le serveur l'interdisait.
--
-- Le garde-fou d'origine voulait empêcher d'ENCAISSER sur une affaire close,
-- ce qui reste juste. Il confondait encaisser et rendre.
--
-- ⚠️ LA LEÇON, qui dépasse ce déclencheur : une contrainte serveur écrite
-- pour un cas d'usage imaginé se vérifie contre le PARCOURS RÉEL, pas contre
-- l'intention. Ici, l'ordre réel des gestes — annuler puis rembourser — n'avait
-- jamais été rejoué en entier. Six jours de saisie locale n'ont rien signalé.

create or replace function public.verifier_paiement_commande()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  montant_du_dossier bigint;
  statut_du_dossier text;
  total_paye bigint;
  total_rembourse bigint;
  net_encaisse bigint;
begin
  select montant_accepte, statut
    into montant_du_dossier, statut_du_dossier
  from public.dossiers_commandes
  where id = new.dossier_id
    and shop_id = new.shop_id
  for update;

  if not found then
    raise exception using
      errcode = '23503',
      message = 'Dossier de commande introuvable pour cette boutique.';
  end if;

  -- Seul l'ENCAISSEMENT est fermé sur une commande annulée. Le remboursement
  -- reste ouvert : c'est la suite normale de l'annulation.
  if statut_du_dossier = 'annulee' and new.type_mouvement = 'paiement' then
    raise exception using
      errcode = '23514',
      message = 'Impossible d''encaisser sur une commande annulée.';
  end if;

  if montant_du_dossier is null then
    raise exception using
      errcode = '23514',
      message = 'Le montant accepté doit être fixé avant d''enregistrer un paiement.';
  end if;

  select
    coalesce(sum(montant) filter (where type_mouvement = 'paiement'), 0),
    coalesce(sum(montant) filter (where type_mouvement = 'remboursement'), 0)
  into total_paye, total_rembourse
  from public.paiements_commandes
  where dossier_id = new.dossier_id
    and shop_id = new.shop_id;

  net_encaisse := total_paye - total_rembourse;

  if new.type_mouvement = 'paiement'
     and net_encaisse + new.montant > montant_du_dossier then
    raise exception using
      errcode = '23514',
      message = format(
        'Paiement refusé : le montant dépasse le solde restant de %s FCFA.',
        montant_du_dossier - net_encaisse
      );
  end if;

  -- On ne rend jamais plus qu'on n'a reçu, annulée ou pas.
  if new.type_mouvement = 'remboursement'
     and new.montant > net_encaisse then
    raise exception using
      errcode = '23514',
      message = format(
        'Remboursement refusé : seulement %s FCFA ont été encaissés.',
        net_encaisse
      );
  end if;

  return new;
end;
$$;
