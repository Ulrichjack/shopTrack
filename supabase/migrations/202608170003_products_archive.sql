-- Archivage d'un produit : il sort du stock, du comptage et de la vente, mais
-- garde tout son passé.
--
-- La suppression ne peut pas jouer ce rôle : effacer un produit cité par une
-- période close réécrirait un bilan déjà consulté — le rapport perdrait une
-- ligne et changerait de bénéfice, sans que personne comprenne pourquoi. Elle
-- reste donc réservée aux produits qui n'ont jamais servi.
--
-- Nullable et sans valeur par défaut : tous les produits existants restent
-- actifs, la migration ne change aucun comportement à elle seule.

alter table public.products
  add column if not exists archived_at timestamptz;

comment on column public.products.archived_at is
  'Renseignée = produit au placard : masqué du stock, du comptage et de la '
  'vente, mais toujours cité par les périodes closes.';

-- Le filtre courant est « les produits actifs de cette boutique ».
create index if not exists products_shop_active_idx
  on public.products (shop_id)
  where archived_at is null;
