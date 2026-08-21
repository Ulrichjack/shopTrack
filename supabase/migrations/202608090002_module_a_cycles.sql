-- Module A — cycles d'approvisionnement et unités (voir
-- docs/ARCHITECTURE_MODULES.md §1 et docs/PLAN_MODULES_CLIENTS.md).
-- N'affecte que les boutiques dont shop_settings.unit_mode = 'hierarchical' ;
-- ne change rien pour les autres (nouvelles tables + colonnes nullable).

create table if not exists public.product_units (
  id uuid primary key,
  product_id uuid not null references public.products(id) on delete cascade,
  unit_name text not null,
  ratio_to_base integer not null check (ratio_to_base > 0),
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

alter table public.product_units enable row level security;

drop policy if exists shoptrack_product_units_members
  on public.product_units;
create policy shoptrack_product_units_members
on public.product_units
for all to authenticated
using (
  exists (
    select 1 from public.products
    where products.id = product_units.product_id
      and public.is_shop_member(products.shop_id)
  )
)
with check (
  exists (
    select 1 from public.products
    where products.id = product_units.product_id
      and public.is_shop_member(products.shop_id)
  )
);

create table if not exists public.supply_cycles (
  id uuid primary key,
  shop_id uuid not null references public.shops(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  opened_at timestamptz not null default now(),
  closed_at timestamptz,
  quantity_received integer not null check (quantity_received >= 0),
  purchase_cost numeric not null check (purchase_cost >= 0),
  reference_margin_per_unit numeric,
  status text not null default 'open' check (status in ('open', 'closed')),
  created_at timestamptz not null default now()
);

alter table public.supply_cycles enable row level security;

drop policy if exists shoptrack_supply_cycles_members
  on public.supply_cycles;
create policy shoptrack_supply_cycles_members
on public.supply_cycles
for all to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));

create table if not exists public.cycle_losses (
  id uuid primary key,
  cycle_id uuid not null references public.supply_cycles(id) on delete cascade,
  quantity integer not null check (quantity > 0),
  reason text not null check (
    reason in ('casse', 'rongeurs', 'deterioration', 'autre')
  ),
  note text,
  created_at timestamptz not null default now()
);

alter table public.cycle_losses enable row level security;

drop policy if exists shoptrack_cycle_losses_members
  on public.cycle_losses;
create policy shoptrack_cycle_losses_members
on public.cycle_losses
for all to authenticated
using (
  exists (
    select 1 from public.supply_cycles
    where supply_cycles.id = cycle_losses.cycle_id
      and public.is_shop_member(supply_cycles.shop_id)
  )
)
with check (
  exists (
    select 1 from public.supply_cycles
    where supply_cycles.id = cycle_losses.cycle_id
      and public.is_shop_member(supply_cycles.shop_id)
  )
);

-- Extension des lignes de vente : nullable, donc aucun impact sur les ventes
-- existantes ni sur les boutiques en mode simple.
alter table public.sale_items
  add column if not exists cycle_id uuid references public.supply_cycles(id),
  add column if not exists unit_id uuid references public.product_units(id),
  add column if not exists quantity_in_base integer,
  add column if not exists unit_sell_price numeric;
