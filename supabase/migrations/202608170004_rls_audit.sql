-- Audit RLS — fermeture d'une porte d'entrée, et ménage.
--
-- Toutes les tables avaient bien RLS actif et au moins une policy. Le
-- problème n'était pas une table oubliée : c'était UNE policy trop
-- généreuse, qui donnait la clé de toutes les autres.

-- ---------------------------------------------------------------------------
-- 1. LE TROU : n'importe qui pouvait se rattacher à n'importe quelle boutique
-- ---------------------------------------------------------------------------
--
-- `allow_insert_members` autorisait l'insertion dès lors que
-- `auth.uid() = user_id` — sans **aucune** contrainte sur `shop_id`. Un compte
-- connecté qui connaissait l'identifiant d'une boutique pouvait donc s'y
-- inscrire lui-même, en se donnant le rôle `owner`, et lire ensuite tout ce
-- que cette boutique contient : produits, ventes, caisse, prix d'achat,
-- clôtures. Tout le reste du modèle repose sur `is_shop_member()` : cette
-- policy était le passe-partout.
--
-- Les deux usages légitimes n'ont jamais eu besoin de tant : à l'inscription
-- et à la création d'une boutique supplémentaire, on s'inscrit dans une
-- boutique **qu'on vient de créer**. Le rattachement d'un vendeur, lui, passe
-- par `shoptrack_members_owner_manage` (le patron) ou par la fonction serveur
-- `creer-vendeur` (service_role, hors RLS).

-- `security definer` : lire `shops` depuis une policy de `shop_members` sans
-- lui rejouerait les policies de `shops`, qui interrogent `shop_members`.
create or replace function public.is_shop_creator(target_shop_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.shops
    where id = target_shop_id
      and owner_id = (select auth.uid())
  );
$$;

revoke all on function public.is_shop_creator(uuid) from public;
revoke all on function public.is_shop_creator(uuid) from anon;
grant execute on function public.is_shop_creator(uuid) to authenticated;

drop policy if exists allow_insert_members on public.shop_members;
create policy shoptrack_members_self_on_own_shop
on public.shop_members
for insert
to authenticated
with check (
  user_id = (select auth.uid())
  and public.is_shop_creator(shop_id)
);

-- Redondante : `shoptrack_members_owner_manage` lit déjà `user_id = auth.uid()`.
drop policy if exists allow_select_members on public.shop_members;

-- ---------------------------------------------------------------------------
-- 2. MÉNAGE : les policies en double
-- ---------------------------------------------------------------------------
--
-- Chacune de ces tables portait deux policies équivalentes : l'ancienne, avec
-- sa sous-requête sur `shop_members` écrite à la main, et la nouvelle qui
-- passe par `is_shop_member()`. Les policies permissives se cumulent en OU :
-- garder les deux n'ouvrait rien de plus, mais obligeait à vérifier deux
-- règles au lieu d'une pour savoir qui voit quoi — et faisait réévaluer
-- `auth.uid()` à chaque ligne, sur chaque requête.
--
-- Supprimer une policy permissive ne peut que **restreindre** : le risque de
-- ce ménage va dans le bon sens.

drop policy if exists products_member_access on public.products;
drop policy if exists sales_member_access on public.sales;
drop policy if exists sale_items_member_access on public.sale_items;
drop policy if exists shop_cash_access on public.cash_movements;
drop policy if exists shop_closing_access on public.daily_closings;
drop policy if exists shop_stock_movements on public.stock_movements;

-- `allow_select_shops` (auth.uid() = owner_id) reste, malgré l'apparence de
-- doublon avec `shoptrack_shops_member_read`. À l'instant précis où une
-- boutique vient d'être créée, son créateur n'en est pas encore membre :
-- c'est cette policy qui laisse passer le `.select()` de retour d'insertion.
-- La supprimer casserait la création de boutique.

-- ---------------------------------------------------------------------------
-- 3. Les fonctions ne sont plus appelables sans être connecté
-- ---------------------------------------------------------------------------
--
-- Sans session, `auth.uid()` est nul et ces fonctions renvoient toujours
-- `false` : elles ne fuitaient rien. Mais rien ne justifie qu'un appelant
-- anonyme puisse les sonder.

revoke all on function public.is_shop_member(uuid) from anon;
revoke all on function public.is_shop_owner(uuid) from anon;
revoke all on function public.apply_stock_movement(uuid, uuid, uuid, integer, text) from anon;
