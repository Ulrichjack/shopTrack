-- Module B — Historique des prix d'un produit.
--
-- Le prix d'achat est déjà figé sur la ligne d'achat (stock_purchases), mais
-- le prix de VENTE restait celui d'aujourd'hui : une période close était
-- valorisée au tarif du moment où on la consultait. Un commerçant qui passe
-- le savon de 350 à 400 F voyait son mois précédent se réévaluer tout seul,
-- et l'écart avec sa caisse devenait faux sans que rien ne le signale.
--
-- Une ligne par changement, avec sa date d'effet. Le rapport valorise ensuite
-- au prix réellement pratiqué pendant la période.

create table if not exists public.product_prices (
  id uuid primary key,
  shop_id uuid not null references public.shops(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  buy_price numeric not null check (buy_price >= 0),
  sell_price numeric not null check (sell_price >= 0),
  effective_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

alter table public.product_prices enable row level security;

drop policy if exists shoptrack_product_prices_members on public.product_prices;
create policy shoptrack_product_prices_members
on public.product_prices
for all to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));

create index if not exists product_prices_shop_product_date
  on public.product_prices (shop_id, product_id, effective_at);

-- Point de départ : le prix actuel de chaque produit devient sa première
-- ligne d'historique. Sans ça, toute période antérieure à la première
-- modification de prix n'aurait aucun tarif de référence.
insert into public.product_prices (
  id, shop_id, product_id, buy_price, sell_price, effective_at
)
select
  gen_random_uuid(),
  p.shop_id,
  p.id,
  p.buy_price,
  p.sell_price,
  coalesce(p.created_at, now())
from public.products p
where not exists (
  select 1 from public.product_prices pp where pp.product_id = p.id
);
