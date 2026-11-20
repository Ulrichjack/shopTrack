-- STAGING UNIQUEMENT. Données fictives annulées en fin de transaction.
-- Vérifie l'isolation des lignes ; ne prouve PAS la confidentialité des
-- colonnes de coût, qui restent accessibles au vendeur via les tables.
begin;

insert into auth.users (id) values
  ('00000000-0000-4000-8000-00000000ee01'),
  ('00000000-0000-4000-8000-00000000ee02'),
  ('00000000-0000-4000-8000-00000000ee03');

insert into public.shops (id, owner_id, name) values
  ('00000000-0000-4000-8000-00000000ee11', '00000000-0000-4000-8000-00000000ee01', 'Test RLS A'),
  ('00000000-0000-4000-8000-00000000ee12', '00000000-0000-4000-8000-00000000ee02', 'Test RLS B');

insert into public.shop_members (shop_id, user_id, role) values
  ('00000000-0000-4000-8000-00000000ee11', '00000000-0000-4000-8000-00000000ee01', 'owner'),
  ('00000000-0000-4000-8000-00000000ee12', '00000000-0000-4000-8000-00000000ee02', 'owner'),
  ('00000000-0000-4000-8000-00000000ee11', '00000000-0000-4000-8000-00000000ee03', 'seller');

insert into public.products (id, shop_id, name, buy_price, sell_price) values
  ('00000000-0000-4000-8000-00000000ee21', '00000000-0000-4000-8000-00000000ee11', 'Produit A', 100, 150),
  ('00000000-0000-4000-8000-00000000ee22', '00000000-0000-4000-8000-00000000ee12', 'Produit B', 200, 300);

insert into public.sales (id, shop_id, user_id, total_amount, total_profit) values
  ('00000000-0000-4000-8000-00000000ee31', '00000000-0000-4000-8000-00000000ee11', '00000000-0000-4000-8000-00000000ee01', 150, 50),
  ('00000000-0000-4000-8000-00000000ee32', '00000000-0000-4000-8000-00000000ee12', '00000000-0000-4000-8000-00000000ee02', 300, 100);

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-4000-8000-00000000ee01';
do $$
begin
  if (select count(*) from public.products where id in
      ('00000000-0000-4000-8000-00000000ee21', '00000000-0000-4000-8000-00000000ee22')) <> 1 then
    raise exception 'Le patron A lit les produits d une autre boutique';
  end if;
  if (select count(*) from public.sales where id in
      ('00000000-0000-4000-8000-00000000ee31', '00000000-0000-4000-8000-00000000ee32')) <> 1 then
    raise exception 'Le patron A lit les ventes d une autre boutique';
  end if;
end;
$$;

set local request.jwt.claim.sub = '00000000-0000-4000-8000-00000000ee03';
do $$
declare changed integer;
begin
  if (select count(*) from public.products where id in
      ('00000000-0000-4000-8000-00000000ee21', '00000000-0000-4000-8000-00000000ee22')) <> 1 then
    raise exception 'Le vendeur A lit les produits d une autre boutique';
  end if;
  if (select count(*) from public.sales where id in
      ('00000000-0000-4000-8000-00000000ee31', '00000000-0000-4000-8000-00000000ee32')) <> 1 then
    raise exception 'Le vendeur A lit les ventes d une autre boutique';
  end if;
  update public.products set name = 'Modification interdite'
  where id = '00000000-0000-4000-8000-00000000ee21';
  get diagnostics changed = row_count;
  if changed <> 0 then
    raise exception 'Le vendeur a modifie le catalogue du patron';
  end if;
end;
$$;

set local request.jwt.claim.sub = '00000000-0000-4000-8000-00000000ee02';
do $$
declare changed integer;
begin
  if (select count(*) from public.products where id =
      '00000000-0000-4000-8000-00000000ee21') <> 0 then
    raise exception 'Le patron B lit le produit A';
  end if;
  update public.products set name = 'Modification interdite'
  where id = '00000000-0000-4000-8000-00000000ee21';
  get diagnostics changed = row_count;
  if changed <> 0 then
    raise exception 'Le patron B a modifie le produit A';
  end if;
end;
$$;

set local role anon;
do $$
begin
  begin
    if (select count(*) from public.products where id in
        ('00000000-0000-4000-8000-00000000ee21', '00000000-0000-4000-8000-00000000ee22')) <> 0 then
      raise exception 'Un visiteur non connecte lit le catalogue';
    end if;
  exception when insufficient_privilege then
    null; -- Après révocation du grant anon, le refus se produit avant RLS.
  end;
end;
$$;

rollback;
