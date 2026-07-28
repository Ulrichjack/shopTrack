-- ShopTrack : synchronisation idempotente et règles d'accès par boutique.
-- À exécuter avec `supabase db push` ou dans l'éditeur SQL Supabase.

create unique index if not exists daily_closings_shop_date_key
  on public.daily_closings (shop_id, closing_date);

create unique index if not exists stock_movements_id_key
  on public.stock_movements (id);

create or replace function public.is_shop_member(target_shop_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.shop_members
    where shop_id = target_shop_id
      and user_id = auth.uid()
  );
$$;

revoke all on function public.is_shop_member(uuid) from public;
grant execute on function public.is_shop_member(uuid) to authenticated;

-- Applique un mouvement une seule fois puis modifie le stock sous verrou.
-- Un nouvel envoi du même UUID ne redécompte jamais le stock.
create or replace function public.apply_stock_movement(
  p_movement_id uuid,
  p_shop_id uuid,
  p_product_id uuid,
  p_quantity_delta integer,
  p_type text
)
returns integer
language plpgsql
security invoker
set search_path = public
as $$
declare
  movement_inserted uuid;
  resulting_quantity integer;
begin
  if not public.is_shop_member(p_shop_id) then
    raise exception 'Accès refusé à cette boutique';
  end if;

  insert into public.stock_movements (
    id, shop_id, product_id, quantity, type
  )
  values (
    p_movement_id, p_shop_id, p_product_id, abs(p_quantity_delta), p_type
  )
  on conflict (id) do nothing
  returning id into movement_inserted;

  if movement_inserted is null then
    select quantity into resulting_quantity
    from public.products
    where id = p_product_id and shop_id = p_shop_id;
    return resulting_quantity;
  end if;

  update public.products
  set quantity = quantity + p_quantity_delta
  where id = p_product_id
    and shop_id = p_shop_id
    and quantity + p_quantity_delta >= 0
  returning quantity into resulting_quantity;

  if resulting_quantity is null then
    raise exception 'Stock insuffisant ou produit introuvable';
  end if;

  return resulting_quantity;
end;
$$;

revoke all on function public.apply_stock_movement(
  uuid, uuid, uuid, integer, text
) from public;
grant execute on function public.apply_stock_movement(
  uuid, uuid, uuid, integer, text
) to authenticated;

alter table public.products enable row level security;
alter table public.sales enable row level security;
alter table public.sale_items enable row level security;
alter table public.cash_movements enable row level security;
alter table public.stock_movements enable row level security;
alter table public.daily_closings enable row level security;

drop policy if exists shoptrack_products_members on public.products;
create policy shoptrack_products_members on public.products
for all to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));

drop policy if exists shoptrack_sales_members on public.sales;
create policy shoptrack_sales_members on public.sales
for all to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));

drop policy if exists shoptrack_sale_items_members on public.sale_items;
create policy shoptrack_sale_items_members on public.sale_items
for all to authenticated
using (
  exists (
    select 1 from public.sales
    where sales.id = sale_items.sale_id
      and public.is_shop_member(sales.shop_id)
  )
)
with check (
  exists (
    select 1 from public.sales
    where sales.id = sale_items.sale_id
      and public.is_shop_member(sales.shop_id)
  )
);

drop policy if exists shoptrack_cash_members on public.cash_movements;
create policy shoptrack_cash_members on public.cash_movements
for all to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));

drop policy if exists shoptrack_stock_members on public.stock_movements;
create policy shoptrack_stock_members on public.stock_movements
for all to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));

drop policy if exists shoptrack_closings_members on public.daily_closings;
create policy shoptrack_closings_members on public.daily_closings
for all to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));
