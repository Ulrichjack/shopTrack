-- Savoir QUI a fait le geste, quand il y a plusieurs vendeuses.
--
-- Le journal affichait « utilisateur 891ff68c ». On l'a remplacé par le rôle —
-- « par la vendeuse » — ce qui suffit avec une seule employée. Avec deux, la
-- question redevient sans réponse : laquelle ?
--
-- Le téléphone vit dans `auth.users`, que le client ne peut pas lire. D'où
-- cette vue, qui expose le strict nécessaire — l'identifiant et le numéro —
-- et RIEN d'autre : ni l'e-mail, ni les métadonnées, ni le hachage du mot de
-- passe.
--
-- ⚠️ QUI PEUT LA LIRE, ET POURQUOI CE CHOIX.
--
-- Le propriétaire de la boutique, uniquement. C'est lui qui a créé ces comptes
-- et qui connaît déjà ces numéros — il les a tapés. Et le journal d'activité
-- est déjà une route réservée au patron (`bossOnlyRoutes`).
--
-- Ouvrir aux membres donnerait à une vendeuse le numéro de sa collègue, pour
-- un usage qui n'existe pas : elle ne lit pas le journal.

create or replace view public.membres_boutique
with (security_invoker = true)
as
select
  m.shop_id,
  m.user_id,
  m.role,
  u.phone as telephone
from public.shop_members m
join auth.users u on u.id = m.user_id
where public.is_shop_owner(m.shop_id);

comment on view public.membres_boutique is
  'Identifiant et téléphone des membres, lisible par le seul propriétaire. Sert à nommer les gestes dans le journal d''activité.';

grant select on public.membres_boutique to authenticated;
