-- STAGING UNIQUEMENT : test d'autorisation sans toucher aux objets Storage.
-- Les utilisateurs et boutiques fictifs sont annulés par ROLLBACK.
begin;

insert into auth.users (id) values
  ('00000000-0000-4000-8000-00000000cc01'),
  ('00000000-0000-4000-8000-00000000dd01'),
  ('00000000-0000-4000-8000-00000000cc02');

insert into public.shops (id, owner_id, name) values
  ('00000000-0000-4000-8000-00000000cc11', '00000000-0000-4000-8000-00000000cc01', 'Photo A'),
  ('00000000-0000-4000-8000-00000000dd11', '00000000-0000-4000-8000-00000000dd01', 'Photo B');

insert into public.shop_members (shop_id, user_id, role) values
  ('00000000-0000-4000-8000-00000000cc11', '00000000-0000-4000-8000-00000000cc01', 'owner'),
  ('00000000-0000-4000-8000-00000000dd11', '00000000-0000-4000-8000-00000000dd01', 'owner'),
  ('00000000-0000-4000-8000-00000000cc11', '00000000-0000-4000-8000-00000000cc02', 'seller');

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-4000-8000-00000000cc01';

do $$
begin
  if not public.can_upload_product_photo('00000000-0000-4000-8000-00000000cc11_1727700000000.jpg') then
    raise exception 'Le propriétaire A doit pouvoir envoyer dans sa boutique';
  end if;
  if public.can_upload_product_photo('00000000-0000-4000-8000-00000000dd11_1727700000000.jpg') then
    raise exception 'Le propriétaire A ne doit pas envoyer dans la boutique B';
  end if;
  if public.can_upload_product_photo('../00000000-0000-4000-8000-00000000cc11_1727700000000.jpg') then
    raise exception 'Un chemin mal formé ne doit pas être accepté';
  end if;
end;
$$;

set local request.jwt.claim.sub = '00000000-0000-4000-8000-00000000cc02';

do $$
begin
  if public.can_upload_product_photo('00000000-0000-4000-8000-00000000cc11_1727700000000.jpg') then
    raise exception 'Un vendeur ne doit pas envoyer une photo produit';
  end if;
end;
$$;

rollback;
