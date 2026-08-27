-- Séparer les droits du propriétaire et du vendeur.
--
-- IMPORTANT : RLS protège des LIGNES, pas des COLONNES. La lecture de
-- `products`, indispensable à la vente actuelle, expose donc encore
-- `buy_price` et `quantity`. De même, `sales.total_profit` ainsi que
-- `sale_items.buy_price` / `sale_items.profit` restent lisibles par le vendeur
-- puisqu'il doit lire ses ventes. Une vue vendeur ou un calcul serveur devra
-- traiter ces colonnes dans une migration séparée.

-- ---------------------------------------------------------------------------
-- 1. Prédicat propriétaire
-- ---------------------------------------------------------------------------
-- Déjà introduit par 202608170001, redéfini ici pour que la frontière de rôle
-- soit autonome et bénéficie du `(select auth.uid())` évalué une fois.
create or replace function public.is_shop_owner(target_shop_id uuid)
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
      and user_id = (select auth.uid())
      and role = 'owner'
  );
$$;

revoke all on function public.is_shop_owner(uuid) from public;
revoke all on function public.is_shop_owner(uuid) from anon;
grant execute on function public.is_shop_owner(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 2. Catalogue opérationnel : membre en lecture, propriétaire en écriture
-- ---------------------------------------------------------------------------

drop policy if exists products_member_access on public.products;
drop policy if exists shoptrack_products_members on public.products;
drop policy if exists shoptrack_products_member_read on public.products;
drop policy if exists shoptrack_products_owner_write on public.products;

create policy shoptrack_products_member_read
on public.products
for select to authenticated
using (public.is_shop_member(shop_id));

create policy shoptrack_products_owner_write
on public.products
for all to authenticated
using (public.is_shop_owner(shop_id))
with check (public.is_shop_owner(shop_id));

-- Les unités font partie du catalogue nécessaire à la vente hiérarchique.
-- Elles ne contiennent ni coût ni marge : le vendeur les lit, seul le patron
-- les configure.
drop policy if exists shoptrack_product_units_members on public.product_units;
drop policy if exists shoptrack_product_units_member_read on public.product_units;
drop policy if exists shoptrack_product_units_owner_write on public.product_units;

create policy shoptrack_product_units_member_read
on public.product_units
for select to authenticated
using (
  exists (
    select 1
    from public.products
    where products.id = product_units.product_id
      and public.is_shop_member(products.shop_id)
  )
);

create policy shoptrack_product_units_owner_write
on public.product_units
for all to authenticated
using (
  exists (
    select 1
    from public.products
    where products.id = product_units.product_id
      and public.is_shop_owner(products.shop_id)
  )
)
with check (
  exists (
    select 1
    from public.products
    where products.id = product_units.product_id
      and public.is_shop_owner(products.shop_id)
  )
);

-- Le vendeur doit connaître le mode de sa boutique pour afficher le bon
-- accueil, mais il ne peut pas changer ce mode.
drop policy if exists shoptrack_shop_settings_members on public.shop_settings;
drop policy if exists shoptrack_shop_settings_member_read on public.shop_settings;
drop policy if exists shoptrack_shop_settings_owner_write on public.shop_settings;

create policy shoptrack_shop_settings_member_read
on public.shop_settings
for select to authenticated
using (public.is_shop_member(shop_id));

create policy shoptrack_shop_settings_owner_write
on public.shop_settings
for all to authenticated
using (public.is_shop_owner(shop_id))
with check (public.is_shop_owner(shop_id));

-- `allow_insert_shops` et `allow_select_shops` restent indispensables au
-- bootstrap : avant l'insertion dans shop_members, is_shop_owner(id) est faux.
-- `shoptrack_shops_member_read` permet ensuite au vendeur de lire le nom.
-- La suppression d'une boutique reste volontairement sans policy : elle
-- cascade sur toutes ses données et n'existe pas dans l'application.
-- ATTENTION : cette policy UPDATE couvre toute la ligne, donc aussi les trois
-- colonnes `abonnement_*`. Elles ne pilotent encore aucun blocage, mais le jour
-- où l'abonnement sera activé elles devront passer derrière une RPC serveur ou
-- des privilèges de colonnes avant de rester fiables.
drop policy if exists shoptrack_shops_owner_update on public.shops;
create policy shoptrack_shops_owner_update
on public.shops
for update to authenticated
using (public.is_shop_owner(id))
with check (public.is_shop_owner(id));

-- ---------------------------------------------------------------------------
-- 3. Données réservées au propriétaire
-- ---------------------------------------------------------------------------

drop policy if exists shoptrack_product_prices_members on public.product_prices;
drop policy if exists shoptrack_product_prices_owner_all on public.product_prices;
create policy shoptrack_product_prices_owner_all
on public.product_prices
for all to authenticated
using (public.is_shop_owner(shop_id))
with check (public.is_shop_owner(shop_id));

-- Oubliée dans la liste initiale, cette table porte les arrivages et leur prix
-- d'achat. La laisser à is_shop_member contredirait « entrées propriétaire ».
drop policy if exists shoptrack_stock_purchases_members on public.stock_purchases;
drop policy if exists shoptrack_stock_purchases_owner_all on public.stock_purchases;
create policy shoptrack_stock_purchases_owner_all
on public.stock_purchases
for all to authenticated
using (public.is_shop_owner(shop_id))
with check (public.is_shop_owner(shop_id));

drop policy if exists shop_cash_access on public.cash_movements;
drop policy if exists shoptrack_cash_members on public.cash_movements;
drop policy if exists shoptrack_cash_owner_all on public.cash_movements;
create policy shoptrack_cash_owner_all
on public.cash_movements
for all to authenticated
using (public.is_shop_owner(shop_id))
with check (public.is_shop_owner(shop_id));

drop policy if exists shop_closing_access on public.daily_closings;
drop policy if exists shoptrack_closings_members on public.daily_closings;
drop policy if exists shoptrack_closings_owner_all on public.daily_closings;
create policy shoptrack_closings_owner_all
on public.daily_closings
for all to authenticated
using (public.is_shop_owner(shop_id))
with check (public.is_shop_owner(shop_id));

drop policy if exists shoptrack_supply_cycles_members on public.supply_cycles;
drop policy if exists shoptrack_supply_cycles_owner_all on public.supply_cycles;
create policy shoptrack_supply_cycles_owner_all
on public.supply_cycles
for all to authenticated
using (public.is_shop_owner(shop_id))
with check (public.is_shop_owner(shop_id));

drop policy if exists shoptrack_cycle_losses_members on public.cycle_losses;
drop policy if exists shoptrack_cycle_losses_owner_all on public.cycle_losses;
create policy shoptrack_cycle_losses_owner_all
on public.cycle_losses
for all to authenticated
using (
  exists (
    select 1
    from public.supply_cycles
    where supply_cycles.id = cycle_losses.cycle_id
      and public.is_shop_owner(supply_cycles.shop_id)
  )
)
with check (
  exists (
    select 1
    from public.supply_cycles
    where supply_cycles.id = cycle_losses.cycle_id
      and public.is_shop_owner(supply_cycles.shop_id)
  )
);

drop policy if exists shoptrack_stock_transfers_members on public.stock_transfers;
drop policy if exists shoptrack_stock_transfers_owner_all on public.stock_transfers;
create policy shoptrack_stock_transfers_owner_all
on public.stock_transfers
for all to authenticated
using (
  public.is_shop_owner(from_shop_id) or public.is_shop_owner(to_shop_id)
)
with check (
  public.is_shop_owner(from_shop_id) or public.is_shop_owner(to_shop_id)
);

-- ---------------------------------------------------------------------------
-- 4. Données opérationnelles : tout membre de la boutique conserve l'accès
-- ---------------------------------------------------------------------------

drop policy if exists sales_member_access on public.sales;
drop policy if exists shoptrack_sales_members on public.sales;
create policy shoptrack_sales_members
on public.sales
for all to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));

drop policy if exists sale_items_member_access on public.sale_items;
drop policy if exists shoptrack_sale_items_members on public.sale_items;
create policy shoptrack_sale_items_members
on public.sale_items
for all to authenticated
using (
  exists (
    select 1
    from public.sales
    where sales.id = sale_items.sale_id
      and public.is_shop_member(sales.shop_id)
  )
)
with check (
  exists (
    select 1
    from public.sales
    where sales.id = sale_items.sale_id
      and public.is_shop_member(sales.shop_id)
  )
);

drop policy if exists shoptrack_inventory_losses_members on public.inventory_losses;
create policy shoptrack_inventory_losses_members
on public.inventory_losses
for all to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));

drop policy if exists shoptrack_shop_takings_members on public.shop_takings;
create policy shoptrack_shop_takings_members
on public.shop_takings
for all to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));

drop policy if exists shoptrack_inventory_counts_members on public.inventory_counts;
create policy shoptrack_inventory_counts_members
on public.inventory_counts
for all to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));

drop policy if exists shop_stock_movements on public.stock_movements;
drop policy if exists shoptrack_stock_members on public.stock_movements;
create policy shoptrack_stock_members
on public.stock_movements
for all to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));

drop policy if exists shoptrack_stock_sync_members on public.stock_sync_operations;
create policy shoptrack_stock_sync_members
on public.stock_sync_operations
for all to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));

-- ---------------------------------------------------------------------------
-- 5. Le vendeur doit encore pouvoir décrémenter le stock lors d'une vente
-- ---------------------------------------------------------------------------
-- La fonction était SECURITY INVOKER : après products.UPDATE réservé au
-- propriétaire, elle échouerait pour chaque vente vendeur. SECURITY DEFINER
-- lui donne uniquement l'écriture atomique nécessaire, après validation de la
-- boutique et du type d'opération. Les recharges et transferts restent patron.
create or replace function public.apply_stock_movement(
  p_movement_id uuid,
  p_shop_id uuid,
  p_product_id uuid,
  p_quantity_delta integer,
  p_type text,
  p_created_at timestamptz default null
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  operation_inserted uuid;
  resulting_quantity integer;
begin
  if not public.is_shop_member(p_shop_id) then
    raise exception 'Accès refusé à cette boutique';
  end if;

  if not public.is_shop_owner(p_shop_id) then
    if p_type in ('sale', 'loss') and p_quantity_delta >= 0 then
      raise exception 'Une vente ou perte vendeur doit diminuer le stock';
    elsif p_type not in ('sale', 'loss', 'inventory_adjustment') then
      raise exception 'Opération de stock réservée au propriétaire';
    end if;
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
$$;

revoke all on function public.apply_stock_movement(
  uuid, uuid, uuid, integer, text, timestamptz
) from public;
revoke all on function public.apply_stock_movement(
  uuid, uuid, uuid, integer, text, timestamptz
) from anon;
grant execute on function public.apply_stock_movement(
  uuid, uuid, uuid, integer, text, timestamptz
) to authenticated;
