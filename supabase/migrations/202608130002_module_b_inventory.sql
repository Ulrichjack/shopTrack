-- Module B — inventaire périodique multi-boutique.
-- Voir docs/ARCHITECTURE_MODULES.md §2 et docs/PLAN_MODULES_CLIENTS.md étape 2.
--
-- Uniquement des tables NOUVELLES : ni products, ni sales, ni stock_movements
-- ne sont modifiés. Le mode simple et le module A ne sont donc pas concernés,
-- et une boutique qui n'active pas ce module ne voit aucune différence.

-- ---------------------------------------------------------------------------
-- 1. Approvisionnements avec le prix payé
-- ---------------------------------------------------------------------------
-- Le prix vit sur la ligne d'achat, pas seulement sur le produit : sinon
-- revaloriser un produit réécrit rétroactivement le coût de toutes les
-- périodes déjà closes. Patron repris de FishCam (LigneAchat.prixUnitaire).
create table if not exists public.stock_purchases (
  id uuid primary key,
  shop_id uuid not null references public.shops(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  quantity integer not null check (quantity > 0),
  unit_cost numeric not null check (unit_cost >= 0),
  purchased_at timestamptz not null default now(),
  note text,
  created_at timestamptz not null default now()
);

alter table public.stock_purchases enable row level security;

drop policy if exists shoptrack_stock_purchases_members on public.stock_purchases;
create policy shoptrack_stock_purchases_members
on public.stock_purchases
for all to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));

create index if not exists stock_purchases_shop_product_date
  on public.stock_purchases (shop_id, product_id, purchased_at);

-- ---------------------------------------------------------------------------
-- 2. Comptages d'inventaire (les points de repère)
-- ---------------------------------------------------------------------------
-- On ne reconstitue jamais le stock passé : on pose des repères. Le stock de
-- départ d'une période est le comptage précédent, ce qui rend le calcul
-- insensible à un mouvement oublié (il ressort comme écart au comptage
-- suivant au lieu de corrompre tout l'historique).
create table if not exists public.inventory_counts (
  id uuid primary key,
  shop_id uuid not null references public.shops(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  counted_at timestamptz not null default now(),
  counted_quantity integer not null check (counted_quantity >= 0),
  -- Repère précédent figé à la saisie : le résultat d'une période close ne
  -- doit plus bouger si un comptage plus ancien est corrigé après coup.
  previous_counted_at timestamptz,
  previous_quantity integer,
  created_at timestamptz not null default now()
);

alter table public.inventory_counts enable row level security;

drop policy if exists shoptrack_inventory_counts_members on public.inventory_counts;
create policy shoptrack_inventory_counts_members
on public.inventory_counts
for all to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));

create index if not exists inventory_counts_shop_product_date
  on public.inventory_counts (shop_id, product_id, counted_at);

-- ---------------------------------------------------------------------------
-- 3. Pertes déclarées (propres au module B)
-- ---------------------------------------------------------------------------
-- Distinctes de cycle_losses, qui appartient au module A et dépend d'un
-- cycle. Sans cette déclaration, le pain invendu jeté chaque soir tomberait
-- dans l'écart inexpliqué et l'app crierait au vol tous les jours.
create table if not exists public.inventory_losses (
  id uuid primary key,
  shop_id uuid not null references public.shops(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  quantity integer not null check (quantity > 0),
  reason text not null check (
    reason in ('casse', 'peremption', 'invendu', 'vol', 'autre')
  ),
  note text,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

alter table public.inventory_losses enable row level security;

drop policy if exists shoptrack_inventory_losses_members on public.inventory_losses;
create policy shoptrack_inventory_losses_members
on public.inventory_losses
for all to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));

create index if not exists inventory_losses_shop_product_date
  on public.inventory_losses (shop_id, product_id, occurred_at);

-- ---------------------------------------------------------------------------
-- 4. Transferts entre boutiques
-- ---------------------------------------------------------------------------
-- Un transfert n'est PAS une vente : la marchandise change d'endroit, aucun
-- client n'a payé. Le coût voyage avec elle, sinon la boutique qui fournit
-- afficherait un chiffre d'affaires fictif et celle qui reçoit une marge
-- écrasée — or c'est justement le bénéfice par boutique que le client veut
-- connaître.
create table if not exists public.stock_transfers (
  id uuid primary key,
  from_shop_id uuid not null references public.shops(id) on delete cascade,
  to_shop_id uuid not null references public.shops(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  quantity integer not null check (quantity > 0),
  -- Renseigné à l'arrivée si quelqu'un vérifie ; l'écart devient une perte
  -- de transport plutôt qu'une vente inexpliquée.
  received_quantity integer check (received_quantity >= 0),
  received_at timestamptz,
  transferred_at timestamptz not null default now(),
  created_by uuid,
  note text,
  created_at timestamptz not null default now(),
  check (from_shop_id <> to_shop_id)
);

alter table public.stock_transfers enable row level security;

-- Visible depuis les deux côtés : l'expéditeur suit son envoi, le
-- destinataire doit pouvoir confirmer ce qu'il a reçu.
drop policy if exists shoptrack_stock_transfers_members on public.stock_transfers;
create policy shoptrack_stock_transfers_members
on public.stock_transfers
for all to authenticated
using (
  public.is_shop_member(from_shop_id) or public.is_shop_member(to_shop_id)
)
with check (
  public.is_shop_member(from_shop_id) or public.is_shop_member(to_shop_id)
);

create index if not exists stock_transfers_from_date
  on public.stock_transfers (from_shop_id, transferred_at);
create index if not exists stock_transfers_to_date
  on public.stock_transfers (to_shop_id, transferred_at);
