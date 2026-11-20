-- Test destructif uniquement dans une transaction annulée : STAGING SEULEMENT.
-- Exécuter avec --linked --project-ref <ref-staging>, jamais sur la production.
begin;

insert into auth.users (id) values
  ('00000000-0000-4000-8000-00000000aa01'),
  ('00000000-0000-4000-8000-00000000bb01');

insert into public.shops (id, owner_id, name) values
  ('00000000-0000-4000-8000-00000000aa11', '00000000-0000-4000-8000-00000000aa01', 'Test A1'),
  ('00000000-0000-4000-8000-00000000aa12', '00000000-0000-4000-8000-00000000aa01', 'Test A2'),
  ('00000000-0000-4000-8000-00000000bb11', '00000000-0000-4000-8000-00000000bb01', 'Test B1');

insert into public.shop_members (shop_id, user_id, role) values
  ('00000000-0000-4000-8000-00000000aa11', '00000000-0000-4000-8000-00000000aa01', 'owner'),
  ('00000000-0000-4000-8000-00000000aa12', '00000000-0000-4000-8000-00000000aa01', 'owner'),
  ('00000000-0000-4000-8000-00000000bb11', '00000000-0000-4000-8000-00000000bb01', 'owner');

insert into public.products (id, shop_id, name, buy_price, sell_price) values
  ('00000000-0000-4000-8000-00000000aa21', '00000000-0000-4000-8000-00000000aa11', 'Produit fictif', 100, 150);

-- Deux lignes existantes simulées : une légitime, une reliant un tiers.
insert into public.stock_transfers (id, from_shop_id, to_shop_id, product_id, quantity) values
  ('00000000-0000-4000-8000-00000000aa31', '00000000-0000-4000-8000-00000000aa11', '00000000-0000-4000-8000-00000000aa12', '00000000-0000-4000-8000-00000000aa21', 1),
  ('00000000-0000-4000-8000-00000000aa32', '00000000-0000-4000-8000-00000000aa11', '00000000-0000-4000-8000-00000000bb11', '00000000-0000-4000-8000-00000000aa21', 1);

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-4000-8000-00000000aa01';

do $$
begin
  if (select count(*) from public.stock_transfers) <> 1 then
    raise exception 'RLS : le propriétaire A doit voir seulement le transfert A1 vers A2';
  end if;

  -- Le vrai transfert entre boutiques du même propriétaire reste possible.
  insert into public.stock_transfers (id, from_shop_id, to_shop_id, product_id, quantity)
  values ('00000000-0000-4000-8000-00000000aa33',
          '00000000-0000-4000-8000-00000000aa11',
          '00000000-0000-4000-8000-00000000aa12',
          '00000000-0000-4000-8000-00000000aa21', 1);

  begin
    insert into public.stock_transfers (id, from_shop_id, to_shop_id, product_id, quantity)
    values ('00000000-0000-4000-8000-00000000aa34',
            '00000000-0000-4000-8000-00000000aa11',
            '00000000-0000-4000-8000-00000000bb11',
            '00000000-0000-4000-8000-00000000aa21', 1);
    raise exception 'RLS : transfert vers une boutique tierce accepté';
  exception when insufficient_privilege then
    null; -- Rejet attendu par WITH CHECK.
  end;
end;
$$;

set local request.jwt.claim.sub = '00000000-0000-4000-8000-00000000bb01';

do $$
begin
  if (select count(*) from public.stock_transfers) <> 0 then
    raise exception 'RLS : le propriétaire B ne doit lire aucun transfert du propriétaire A';
  end if;
end;
$$;

rollback;
