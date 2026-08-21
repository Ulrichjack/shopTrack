-- Le patron gère les comptes de ses boutiques.
--
-- La policy d'origine de `shop_members` n'autorisait qu'à s'inscrire soi-même
-- (`user_id = auth.uid()`), ce qui suffisait tant qu'un compte valait une
-- boutique. Depuis B7bis, le patron crée des comptes vendeurs et les rattache :
-- l'insertion était refusée avec « new row violates row-level security policy ».
--
-- Les policies permissives se cumulent en OU : celle-ci s'ajoute à l'existante
-- sans la remplacer, et l'inscription initiale continue de fonctionner (au
-- moment où il crée sa boutique, le patron n'en est pas encore membre).

-- `security definer` est indispensable : une policy sur `shop_members` qui
-- interrogerait `shop_members` sans lui déclencherait une récursion infinie.
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
      and user_id = auth.uid()
      and role = 'owner'
  );
$$;

revoke all on function public.is_shop_owner(uuid) from public;
grant execute on function public.is_shop_owner(uuid) to authenticated;

drop policy if exists shoptrack_members_owner_manage on public.shop_members;
create policy shoptrack_members_owner_manage
on public.shop_members
for all
to authenticated
-- Lecture : le patron voit les membres de ses boutiques, chacun voit sa ligne.
using (public.is_shop_owner(shop_id) or user_id = auth.uid())
-- Écriture : seul le patron rattache ou retire quelqu'un.
with check (public.is_shop_owner(shop_id));

-- Contrôle : un compte ne doit pas être rattaché deux fois à la même boutique.
create unique index if not exists shop_members_shop_user_key
  on public.shop_members (shop_id, user_id);
