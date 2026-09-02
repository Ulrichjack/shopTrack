-- Ce qu'une commande a coûté, en un seul nombre.
--
-- Décidé le 01/09 après avoir failli construire l'inverse. La version riche —
-- une recette, ligne par ligne, avec décompte du stock — était prête à être
-- écrite. Elle a été écartée pour une raison qui n'est pas technique :
--
--   un gâteau de mariage, c'est neuf lignes d'ingrédients avec leurs
--   quantités. Cinq à dix gâteaux par mois. Le risque n'est pas qu'elle
--   refuse, c'est qu'elle le fasse quinze jours puis s'arrête — et un
--   historique de coûts à moitié rempli MENT : le bilan afficherait des
--   gâteaux à 90 % de marge (coût non saisi) à côté de gâteaux à 60 %.
--
-- Un champ unique donne l'essentiel — bénéfice par commande, par mois, par
-- métier — pour dix secondes de saisie au lieu de trois minutes. Et il nous
-- dira en un mois si elle le remplit. Si oui, la recette sera méritée, et on
-- connaîtra ses vrais ingrédients par ses propres chiffres.
--
-- Réservé à la propriétaire, pour deux raisons qui convergent : elle seule
-- achète les ingrédients et fait le gâteau, et c'est le chiffre que toute
-- l'application cache déjà à la vendeuse (prix d'achat, marges, bilan).
--
-- La règle du module, qu'on peut désormais énoncer :
--   ce qui bloque une cliente au comptoir appartient à la vendeuse ;
--   ce qui peut attendre appartient à la patronne.
-- Une cliente ne reste pas debout à attendre un coût de revient.

alter table public.dossiers_commandes
  add column if not exists cout_matiere bigint
    check (cout_matiere is null or cout_matiere >= 0);

comment on column public.dossiers_commandes.cout_matiere is
  'Ce que la commande a coûté, saisi à la livraison par la propriétaire. Nul = pas encore renseigné, jamais zéro.';

-- Le coût n'est PAS ouvert au membre : sa politique de mise à jour existe déjà
-- et ne peut pas filtrer une colonne (RLS filtre des lignes). On s'appuie donc
-- sur un déclencheur, qui refuse au membre de toucher cette colonne-là.
create or replace function public.verifier_cout_commande()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.cout_matiere is distinct from old.cout_matiere
     and not public.is_shop_owner(new.shop_id) then
    raise exception using
      errcode = '42501',
      message = 'Seule la propriétaire enregistre ce qu''une commande a coûté.';
  end if;
  return new;
end;
$$;

drop trigger if exists verifier_cout_commande on public.dossiers_commandes;
create trigger verifier_cout_commande
  before update on public.dossiers_commandes
  for each row
  execute function public.verifier_cout_commande();
