-- RETOUR ARRIÈRE de 202608270001_owner_seller_rls.sql
--
-- ⚠️ Ce fichier n'est PAS une migration. Il ne doit jamais partir avec
-- `supabase db push` : il n'est pas dans `supabase/migrations/` exprès.
-- On le colle dans l'éditeur SQL de Supabase, à la main, et seulement si la
-- séparation propriétaire/vendeur casse quelque chose en production.
--
-- Il restaure EXACTEMENT l'état du 27/08/2026 avant application : les
-- 17 politiques « tout membre peut tout faire » et la version de
-- `apply_stock_movement` qui n'était pas SECURITY DEFINER.
--
-- Généré depuis la base elle-même (`pg_policies`, `pg_get_functiondef`), pas
-- écrit à la main : une politique restaurée de mémoire, à une parenthèse près,
-- rouvrirait ou fermerait plus que prévu sans que rien ne le signale.
--
-- Après l'avoir utilisé, les nouvelles politiques `*_member_read` et
-- `*_owner_write` n'existent plus : la migration peut être corrigée puis
-- rejouée.

begin;

-- ---------------------------------------------------------------------------
-- 1. Les 17 politiques d'origine
-- ---------------------------------------------------------------------------

drop policy if exists shoptrack_cash_members on public.cash_movements;
create policy shoptrack_cash_members on public.cash_movements for ALL to authenticated using (is_shop_member(shop_id)) with check (is_shop_member(shop_id));

drop policy if exists shoptrack_cycle_losses_members on public.cycle_losses;
create policy shoptrack_cycle_losses_members on public.cycle_losses for ALL to authenticated using ((EXISTS ( SELECT 1
   FROM supply_cycles
  WHERE ((supply_cycles.id = cycle_losses.cycle_id) AND is_shop_member(supply_cycles.shop_id))))) with check ((EXISTS ( SELECT 1
   FROM supply_cycles
  WHERE ((supply_cycles.id = cycle_losses.cycle_id) AND is_shop_member(supply_cycles.shop_id)))));

drop policy if exists shoptrack_closings_members on public.daily_closings;
create policy shoptrack_closings_members on public.daily_closings for ALL to authenticated using (is_shop_member(shop_id)) with check (is_shop_member(shop_id));

drop policy if exists shoptrack_inventory_counts_members on public.inventory_counts;
create policy shoptrack_inventory_counts_members on public.inventory_counts for ALL to authenticated using (is_shop_member(shop_id)) with check (is_shop_member(shop_id));

drop policy if exists shoptrack_inventory_losses_members on public.inventory_losses;
create policy shoptrack_inventory_losses_members on public.inventory_losses for ALL to authenticated using (is_shop_member(shop_id)) with check (is_shop_member(shop_id));

drop policy if exists shoptrack_product_prices_members on public.product_prices;
create policy shoptrack_product_prices_members on public.product_prices for ALL to authenticated using (is_shop_member(shop_id)) with check (is_shop_member(shop_id));

drop policy if exists shoptrack_product_units_members on public.product_units;
create policy shoptrack_product_units_members on public.product_units for ALL to authenticated using ((EXISTS ( SELECT 1
   FROM products
  WHERE ((products.id = product_units.product_id) AND is_shop_member(products.shop_id))))) with check ((EXISTS ( SELECT 1
   FROM products
  WHERE ((products.id = product_units.product_id) AND is_shop_member(products.shop_id)))));

drop policy if exists shoptrack_products_members on public.products;
create policy shoptrack_products_members on public.products for ALL to authenticated using (is_shop_member(shop_id)) with check (is_shop_member(shop_id));

drop policy if exists shoptrack_sale_items_members on public.sale_items;
create policy shoptrack_sale_items_members on public.sale_items for ALL to authenticated using ((EXISTS ( SELECT 1
   FROM sales
  WHERE ((sales.id = sale_items.sale_id) AND is_shop_member(sales.shop_id))))) with check ((EXISTS ( SELECT 1
   FROM sales
  WHERE ((sales.id = sale_items.sale_id) AND is_shop_member(sales.shop_id)))));

drop policy if exists shoptrack_sales_members on public.sales;
create policy shoptrack_sales_members on public.sales for ALL to authenticated using (is_shop_member(shop_id)) with check (is_shop_member(shop_id));

drop policy if exists shoptrack_shop_settings_members on public.shop_settings;
create policy shoptrack_shop_settings_members on public.shop_settings for ALL to authenticated using (is_shop_member(shop_id)) with check (is_shop_member(shop_id));

drop policy if exists shoptrack_shop_takings_members on public.shop_takings;
create policy shoptrack_shop_takings_members on public.shop_takings for ALL to authenticated using (is_shop_member(shop_id)) with check (is_shop_member(shop_id));

drop policy if exists shoptrack_stock_members on public.stock_movements;
create policy shoptrack_stock_members on public.stock_movements for ALL to authenticated using (is_shop_member(shop_id)) with check (is_shop_member(shop_id));

drop policy if exists shoptrack_stock_purchases_members on public.stock_purchases;
create policy shoptrack_stock_purchases_members on public.stock_purchases for ALL to authenticated using (is_shop_member(shop_id)) with check (is_shop_member(shop_id));

drop policy if exists shoptrack_stock_sync_members on public.stock_sync_operations;
create policy shoptrack_stock_sync_members on public.stock_sync_operations for ALL to authenticated using (is_shop_member(shop_id)) with check (is_shop_member(shop_id));

drop policy if exists shoptrack_stock_transfers_members on public.stock_transfers;
create policy shoptrack_stock_transfers_members on public.stock_transfers for ALL to authenticated using ((is_shop_member(from_shop_id) OR is_shop_member(to_shop_id))) with check ((is_shop_member(from_shop_id) OR is_shop_member(to_shop_id)));

drop policy if exists shoptrack_supply_cycles_members on public.supply_cycles;
create policy shoptrack_supply_cycles_members on public.supply_cycles for ALL to authenticated using (is_shop_member(shop_id)) with check (is_shop_member(shop_id));

-- ---------------------------------------------------------------------------
-- 2. Les politiques ajoutées par la migration, à retirer
-- ---------------------------------------------------------------------------
drop policy if exists shoptrack_cash_owner_all on public.cash_movements;
drop policy if exists shoptrack_closings_owner_all on public.daily_closings;
drop policy if exists shoptrack_cycle_losses_owner_all on public.cycle_losses;
drop policy if exists shoptrack_inventory_counts_members on public.inventory_counts;
drop policy if exists shoptrack_inventory_losses_members on public.inventory_losses;
drop policy if exists shoptrack_product_prices_owner_all on public.product_prices;
drop policy if exists shoptrack_products_member_read on public.products;
drop policy if exists shoptrack_products_owner_write on public.products;
drop policy if exists shoptrack_product_units_member_read on public.product_units;
drop policy if exists shoptrack_product_units_owner_write on public.product_units;
drop policy if exists shoptrack_sale_items_members on public.sale_items;
drop policy if exists shoptrack_sales_members on public.sales;
drop policy if exists shoptrack_shop_settings_member_read on public.shop_settings;
drop policy if exists shoptrack_shop_settings_owner_write on public.shop_settings;
drop policy if exists shoptrack_shops_owner_update on public.shops;
drop policy if exists shoptrack_shop_takings_members on public.shop_takings;
drop policy if exists shoptrack_stock_members on public.stock_movements;
drop policy if exists shoptrack_stock_purchases_owner_all on public.stock_purchases;
drop policy if exists shoptrack_stock_sync_members on public.stock_sync_operations;
drop policy if exists shoptrack_stock_transfers_owner_all on public.stock_transfers;
drop policy if exists shoptrack_supply_cycles_owner_all on public.supply_cycles;

-- ---------------------------------------------------------------------------
-- 3. `apply_stock_movement` dans sa version d'avant
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.apply_stock_movement(p_movement_id uuid, p_shop_id uuid, p_product_id uuid, p_quantity_delta integer, p_type text, p_created_at timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS integer
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
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

  -- Déjà appliqué : on rend le stock courant sans rien retoucher. C'est ce qui
  -- rend l'opération rejouable sans danger quand le réseau a coupé au retour.
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

  -- Conserver l'historique des recharges. Les ventes sont déjà détaillées
  -- dans sale_items et peuvent être interdites par l'ancien CHECK.
  if p_type = 'recharge' then
    insert into public.stock_movements (
      id, shop_id, product_id, quantity, type, created_at
    )
    values (
      p_movement_id, p_shop_id, p_product_id, abs(p_quantity_delta), 'recharge',
      coalesce(p_created_at, now())
    )
    on conflict (id) do nothing;
  end if;

  return resulting_quantity;
end;
$function$
;
commit;
