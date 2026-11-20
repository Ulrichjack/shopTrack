-- Vente web atomique du mode simple : vente, lignes et décrément du stock.
-- La même opération UUID peut être rejouée sans revendre deux fois.
create or replace function public.web_create_simple_sale(
  p_shop_id uuid,
  p_sale_id uuid,
  p_items jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  ligne jsonb;
  produit public.products%rowtype;
  quantite integer;
  prix numeric;
  total numeric := 0;
  profit numeric := 0;
  deja public.sales%rowtype;
begin
  if (select auth.uid()) is null or not public.is_shop_member(p_shop_id) then
    raise exception 'Accès refusé à cette boutique.' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.shop_settings
    where shop_id = p_shop_id
      and sale_capture_mode = 'realtime' and unit_mode = 'simple'
  ) then
    raise exception 'Vente réservée au mode simple.' using errcode = '22023';
  end if;
  if jsonb_typeof(p_items) <> 'array'
    or jsonb_array_length(p_items) < 1
    or jsonb_array_length(p_items) > 100 then
    raise exception 'Panier invalide.' using errcode = '22023';
  end if;
  if exists (
    select 1 from jsonb_array_elements(p_items) as entry(value)
    group by entry.value->>'product_id'
    having count(*) > 1
  ) then
    raise exception 'Produit présent deux fois dans le panier.'
      using errcode = '22023';
  end if;

  select * into deja from public.sales where id = p_sale_id;
  if found then
    if deja.shop_id <> p_shop_id or deja.user_id <> (select auth.uid()) then
      raise exception 'Identifiant de vente déjà utilisé.' using errcode = '23505';
    end if;
    return p_sale_id;
  end if;

  -- Même ordre de verrouillage pour deux ventes concurrentes : une vente ne
  -- peut jamais faire passer le stock sous zéro ni se croiser en impasse.
  for ligne in
    select entry.value from jsonb_array_elements(p_items) as entry(value)
    order by entry.value->>'product_id'
  loop
    quantite := (ligne->>'quantity')::integer;
    prix := (ligne->>'sell_price')::numeric;
    if quantite is null or quantite <= 0 or prix is null or prix < 0
      or prix <> trunc(prix) then
      raise exception 'Quantité ou prix invalide.' using errcode = '22023';
    end if;
    select * into produit from public.products
    where id = (ligne->>'product_id')::uuid
      and shop_id = p_shop_id and archived_at is null
    for update;
    if not found or produit.quantity < quantite then
      raise exception 'Stock insuffisant ou produit introuvable.'
        using errcode = '23514';
    end if;
    total := total + prix * quantite;
    profit := profit + (prix - produit.buy_price) * quantite;
  end loop;

  insert into public.sales (
    id, shop_id, user_id, total_amount, total_profit, created_at
  ) values (
    p_sale_id, p_shop_id, (select auth.uid()), total, profit, now()
  );

  for ligne in
    select entry.value from jsonb_array_elements(p_items) as entry(value)
    order by entry.value->>'product_id'
  loop
    quantite := (ligne->>'quantity')::integer;
    prix := (ligne->>'sell_price')::numeric;
    select * into produit from public.products
    where id = (ligne->>'product_id')::uuid and shop_id = p_shop_id
    for update;
    insert into public.sale_items (
      id, sale_id, product_id, product_name, quantity,
      sell_price, buy_price, profit
    ) values (
      gen_random_uuid(), p_sale_id, produit.id, produit.name, quantite,
      prix, produit.buy_price, (prix - produit.buy_price) * quantite
    );
    perform public.apply_stock_movement(
      gen_random_uuid(), p_shop_id, produit.id, -quantite, 'sale', now()
    );
  end loop;
  return p_sale_id;
end;
$$;

revoke all on function public.web_create_simple_sale(uuid, uuid, jsonb)
  from public;
revoke all on function public.web_create_simple_sale(uuid, uuid, jsonb)
  from anon;
grant execute on function public.web_create_simple_sale(uuid, uuid, jsonb)
  to authenticated;
