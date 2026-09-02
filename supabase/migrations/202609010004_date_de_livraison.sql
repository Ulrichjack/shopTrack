-- Le jour où la commande a été livrée.
--
-- Manquait, et le manque ne se voyait pas : `statut = 'terminee'` dit QU'ELLE
-- est livrée, jamais QUAND. Or c'est ce jour-là que le bénéfice tombe dans le
-- bilan. Sans cette colonne, un gâteau livré le 10 septembre aurait compté au
-- jour de sa commande — parfois un mois plus tôt, parfois dans un bilan déjà
-- consulté et imprimé.
--
-- `date_prevue` ne pouvait pas servir : c'est une intention, pas un fait. Elle
-- est souvent vide, et quand elle est là, elle se trompe d'un jour ou deux.

alter table public.dossiers_commandes
  add column if not exists livree_at timestamptz;

comment on column public.dossiers_commandes.livree_at is
  'Jour de la livraison réelle. C''est la date qui compte pour le bilan, jamais date_prevue.';

-- Les commandes déjà marquées livrées avant cette migration n'ont pas de date.
-- On leur donne leur date de création plutôt que de les laisser hors bilan :
-- fausse d'un jour vaut mieux qu'absente, et le volume est nul (module neuf).
update public.dossiers_commandes
   set livree_at = created_at
 where statut = 'terminee'
   and livree_at is null;
