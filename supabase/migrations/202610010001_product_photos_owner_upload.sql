-- Les URL des photos restent publiques pour l'Android actuel ; cette migration
-- limite l'envoi et la lecture des métadonnées Storage au propriétaire.
-- Le passage à un bucket privé demandera une adaptation du client mobile/web.
insert into storage.buckets (id, name, public)
values ('product-photos', 'product-photos', true)
on conflict (id) do nothing;

-- Le client actuel envoie <shop_uuid>_<epoch_ms>.jpg à la racine du bucket.
-- CASE évite de convertir en UUID un nom mal formé.
create or replace function public.can_upload_product_photo(object_name text)
returns boolean
language sql
stable
set search_path = public
as $$
  select case
    when object_name ~
      '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}_[0-9]{13}\.jpg$'
    then public.is_shop_owner(split_part(object_name, '_', 1)::uuid)
    else false
  end;
$$;

revoke all on function public.can_upload_product_photo(text) from public;
revoke all on function public.can_upload_product_photo(text) from anon;
grant execute on function public.can_upload_product_photo(text) to authenticated;

drop policy if exists "Allow Insert 1a5cjkv_0" on storage.objects;
drop policy if exists shoptrack_photo_owner_insert on storage.objects;
create policy shoptrack_photo_owner_insert
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'product-photos'
  and public.can_upload_product_photo(name)
);

-- Supabase Storage peut avoir besoin de SELECT pour retourner l'objet créé.
-- Cela ne rend pas le bucket privé : ses URL publiques restent accessibles.
drop policy if exists shoptrack_photo_owner_select on storage.objects;
create policy shoptrack_photo_owner_select
on storage.objects
for select to authenticated
using (
  bucket_id = 'product-photos'
  and public.can_upload_product_photo(name)
);
