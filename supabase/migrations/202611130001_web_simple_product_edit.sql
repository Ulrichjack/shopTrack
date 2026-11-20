-- Édition atomique d'une fiche du mode simple depuis le web.
-- Le tarif et sa ligne d'historique changent dans la même transaction.
-- La production reste en lecture seule : appliquer et tester sur staging.
create or replace function public.web_update_simple_product(
  p_shop_id uuid,
  p_product_id uuid,
  p_expected_updated_at timestamptz,
  p_name text,
  p_unit text,
  p_barcode text,
  p_min_quantity integer,
  p_buy_price numeric,
  p_sell_price numeric
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  ancien public.products%rowtype;
  instant timestamptz := clock_timestamp();
  prix_changes boolean;
begin
  if (select auth.uid()) is null or not public.is_shop_owner(p_shop_id) then
    raise exception 'Seul le propriétaire peut modifier les prix.'
      using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.shop_settings
    where shop_id = p_shop_id
      and sale_capture_mode = 'realtime' and unit_mode = 'simple'
  ) then
    raise exception 'Cette opération est réservée au mode simple.'
      using errcode = '22023';
  end if;

  if nullif(btrim(p_name), '') is null or length(btrim(p_name)) > 120
    or p_unit is not null and length(btrim(p_unit)) > 30
    or p_barcode is not null and length(btrim(p_barcode)) > 100
    or p_min_quantity is null or p_min_quantity < 0
    or p_buy_price is null or p_buy_price < 0
    or p_sell_price is null or p_sell_price < 0
    or p_buy_price <> trunc(p_buy_price)
    or p_sell_price <> trunc(p_sell_price)
  then
    raise exception 'Valeurs du produit invalides.' using errcode = '22023';
  end if;

  select * into ancien
  from public.products
  where id = p_product_id and shop_id = p_shop_id and archived_at is null
  for update;
  if not found then
    raise exception 'Produit introuvable.' using errcode = 'P0002';
  end if;
  if ancien.updated_at is distinct from p_expected_updated_at then
    raise exception 'La fiche a changé depuis son ouverture. Actualiser.'
      using errcode = '40001';
  end if;

  prix_changes := ancien.buy_price is distinct from p_buy_price
    or ancien.sell_price is distinct from p_sell_price;

  if prix_changes and not exists (
    select 1 from public.product_prices where product_id = p_product_id
  ) then
    insert into public.product_prices (
      id, shop_id, product_id, buy_price, sell_price, effective_at
    ) values (
      gen_random_uuid(), p_shop_id, p_product_id,
      ancien.buy_price, ancien.sell_price,
      least(coalesce(ancien.created_at, instant), instant)
    );
  end if;

  update public.products set
    name = btrim(p_name),
    unit = nullif(btrim(p_unit), ''),
    barcode = coalesce(nullif(btrim(p_barcode), ''), 'QR-' || p_product_id::text),
    min_quantity = p_min_quantity,
    buy_price = p_buy_price,
    sell_price = p_sell_price,
    updated_at = instant
  where id = p_product_id and shop_id = p_shop_id;

  if prix_changes then
    insert into public.product_prices (
      id, shop_id, product_id, buy_price, sell_price, effective_at
    ) values (
      gen_random_uuid(), p_shop_id, p_product_id,
      p_buy_price, p_sell_price, instant
    );
  end if;

  return p_product_id;
end;
$$;

revoke all on function public.web_update_simple_product(
  uuid, uuid, timestamptz, text, text, text, integer, numeric, numeric
) from public;
revoke all on function public.web_update_simple_product(
  uuid, uuid, timestamptz, text, text, text, integer, numeric, numeric
) from anon;
grant execute on function public.web_update_simple_product(
  uuid, uuid, timestamptz, text, text, text, integer, numeric, numeric
) to authenticated;
