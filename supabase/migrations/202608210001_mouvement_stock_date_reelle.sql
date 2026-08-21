-- Dater un mouvement de stock du jour où la marchandise est ARRIVÉE.
--
-- `apply_stock_movement` laissait `stock_movements.created_at` prendre sa
-- valeur par défaut, c'est-à-dire l'instant de l'ENVOI. Une livraison du lundi
-- notée le mercredi soir s'affichait au mercredi dans l'historique du produit,
-- et sur un deuxième téléphone elle portait la date de la synchronisation.
--
-- Le paramètre est optionnel et arrive en dernier : tous les appels existants
-- — ventes, transferts, recharges du mode simple — continuent de fonctionner
-- sans être modifiés, et retombent sur `now()`.
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
set search_path to 'public'
as $function$
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
$function$;
