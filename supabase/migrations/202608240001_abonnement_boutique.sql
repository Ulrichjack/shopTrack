-- Le registre des abonnements, sans le blocage.
--
-- Trois colonnes pour savoir qui paie et jusqu'à quand. Aucune vérification
-- n'est branchée dessus : l'app ne les lit pas encore, personne ne peut être
-- coupé par accident. C'est volontaire — on pose le registre pendant qu'il n'y
-- a qu'un client, le blocage viendra quand il y en aura plusieurs.
--
-- `abonnement_actif` vaut vrai par défaut. Le jour où une vérification sera
-- ajoutée, une boutique oubliée continuera de fonctionner : couper l'accès à
-- quelqu'un qui a payé coûte plus cher que laisser passer quelqu'un qui n'a
-- pas payé.
--
-- Personne ne peut les modifier depuis l'application : la table `shops` n'a
-- aucune politique UPDATE (voir le renommage de boutique, retiré le 21/08 pour
-- cette raison). Ces colonnes se remplissent depuis la console Supabase, à la
-- main, par le vendeur du logiciel.
alter table public.shops
  add column if not exists abonnement_actif boolean not null default true,
  add column if not exists abonnement_jusqu_au date,
  add column if not exists abonnement_note text;

comment on column public.shops.abonnement_actif is
  'Faux = abonnement suspendu. Aucun effet tant que la vérification n''est pas branchée.';
comment on column public.shops.abonnement_jusqu_au is
  'Dernier jour couvert par le paiement. Null = jamais payé, ou période d''essai.';
comment on column public.shops.abonnement_note is
  'Trace libre : moyen de paiement, montant, date de réception.';
