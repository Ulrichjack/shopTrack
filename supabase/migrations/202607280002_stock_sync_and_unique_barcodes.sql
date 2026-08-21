-- Corrige les mouvements de vente bloqués et interdit les QR dupliqués.
-- À appliquer après 202607270001_secure_sync.sql.

-- Table technique séparée : certains anciens schémas n'autorisent que
-- le type "recharge" dans stock_movements.
create table if not exists public.stock_sync_operations (
  id uuid primary key,
  shop_id uuid not null references public.shops(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  quantity_delta integer not null,
  operation_type text not null,
  created_at timestamptz not null default now()
);

alter table public.stock_sync_operations enable row level security;

drop policy if exists shoptrack_stock_sync_members
  on public.stock_sync_operations;
create policy shoptrack_stock_sync_members
on public.stock_sync_operations
for all to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));

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
  operation_inserted uuid;
  resulting_quantity integer;
begin
  if not public.is_shop_member(p_shop_id) then
    raise exception 'Accès refusé à cette boutique';
  end if;

  insert into public.stock_sync_operations (
    id, shop_id, product_id, quantity_delta, operation_type
  )
  values (
    p_movement_id, p_shop_id, p_product_id, p_quantity_delta, p_type
  )
  on conflict (id) do nothing
  returning id into operation_inserted;

  if operation_inserted is null then
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

  -- Conserver l'historique historique des recharges. Les ventes sont déjà
  -- détaillées dans sale_items et peuvent être interdites par l'ancien CHECK.
  if p_type = 'recharge' then
    insert into public.stock_movements (
      id, shop_id, product_id, quantity, type
    )
    values (
      p_movement_id, p_shop_id, p_product_id, abs(p_quantity_delta), 'recharge'
    )
    on conflict (id) do nothing;
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

-- Réparer les doublons existants sans supprimer de produit :
-- le premier conserve son code, les suivants reçoivent un nouveau QR interne.
with ranked_barcodes as (
  select
    id,
    row_number() over (
      partition by shop_id, barcode
      order by id
    ) as duplicate_rank
  from public.products
  where barcode is not null and btrim(barcode) <> ''
)
update public.products as product
set barcode = 'QR-MIGRATED-' || product.id::text
from ranked_barcodes
where product.id = ranked_barcodes.id
  and ranked_barcodes.duplicate_rank > 1;

create unique index if not exists products_shop_barcode_key
  on public.products (shop_id, barcode)
  where barcode is not null and btrim(barcode) <> '';
