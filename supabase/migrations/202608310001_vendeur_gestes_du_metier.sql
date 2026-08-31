-- Rendre au vendeur les gestes de son métier.
--
-- La séparation des rôles du 27/08 a fermé trop large. La cliente demandait de
-- cacher l'ARGENT — prix d'achat, marges, totaux — pas d'empêcher la personne
-- qui tient la boutique de faire son travail. Constaté à l'usage le 31/08 :
-- créer un article, archiver un produit et clôturer la journée étaient refusés
-- par le serveur, sans que rien à l'écran ne l'explique.
--
-- Le principe retenu, celui-là même adopté pour les entrées de stock : la
-- propriétaire ne valide pas AVANT, elle relit APRÈS. Un contrôle qui attend
-- quelqu'un d'absent n'est pas un contrôle, c'est un blocage — et le
-- commerçant contourne alors l'application avec un cahier.

-- ---------------------------------------------------------------------------
-- 1. Créer un article
-- ---------------------------------------------------------------------------
-- La marchandise arrive quand elle arrive. Attendre la propriétaire pour
-- l'enregistrer revient à vendre un produit que l'application ignore.
--
-- L'écran masque le prix d'achat au vendeur et l'enregistre à zéro : la
-- propriétaire le complétera. Un zéro se remarque, un prix inventé non.
--
-- MODIFIER reste réservé au patron : changer un prix engage toutes les ventes
-- à venir, ce n'est pas le même geste que déclarer un article nouveau.
drop policy if exists shoptrack_products_seller_insert on public.products;

create policy shoptrack_products_seller_insert
on public.products
for insert to authenticated
with check (public.is_shop_member(shop_id));

-- ---------------------------------------------------------------------------
-- 2. Archiver et réactiver un produit
-- ---------------------------------------------------------------------------
-- RLS travaille par LIGNE, pas par colonne : autoriser l'UPDATE pour ranger un
-- produit autoriserait aussi à changer son prix. D'où une fonction dédiée qui
-- ne touche qu'à `archived_at`, sur le modèle d'`apply_stock_movement`.
create or replace function public.basculer_archivage_produit(
  p_product_id uuid,
  p_archive boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_shop_id uuid;
begin
  select shop_id into v_shop_id from public.products where id = p_product_id;
  if v_shop_id is null then
    raise exception 'Produit introuvable';
  end if;

  -- `security definer` contourne RLS par construction : la vérification
  -- d'appartenance doit donc se faire ici, sinon n'importe qui pourrait ranger
  -- les produits de n'importe quelle boutique.
  if not public.is_shop_member(v_shop_id) then
    raise exception 'Accès refusé à cette boutique';
  end if;

  update public.products
  set archived_at = case when p_archive then now() else null end
  where id = p_product_id;
end;
$$;

revoke all on function public.basculer_archivage_produit(uuid, boolean) from public;
revoke all on function public.basculer_archivage_produit(uuid, boolean) from anon;
grant execute on function public.basculer_archivage_produit(uuid, boolean) to authenticated;

-- ---------------------------------------------------------------------------
-- 3. Enregistrer une sortie de caisse
-- ---------------------------------------------------------------------------
-- Si le vendeur paie le transport avec l'argent du tiroir sans pouvoir
-- l'enregistrer, la caisse ne tombe plus juste le soir — et le manquant LUI
-- est attribué. Mieux vaut qu'il déclare et que la propriétaire relise.
--
-- INSERT seulement : une sortie enregistrée ne se modifie ni ne s'efface. Une
-- erreur se corrige par une entrée compensatoire, qui laisse une trace.
drop policy if exists shoptrack_cash_seller_insert on public.cash_movements;

create policy shoptrack_cash_seller_insert
on public.cash_movements
for insert to authenticated
with check (public.is_shop_member(shop_id));

-- ---------------------------------------------------------------------------
-- 4. Clôturer la journée
-- ---------------------------------------------------------------------------
-- C'est le vendeur qui compte le tiroir en fermant : la propriétaire n'est pas
-- là. Sans ce droit, les journées s'empilent sans comptage et l'écart réel
-- n'apparaît jamais — or c'est précisément ce que la clôture sert à révéler.
--
-- Il ne VOIT pas le bilan pour autant : `/bilan` et `/inventory-report`
-- restent fermés côté application. Il constate, il ne consulte pas.
drop policy if exists shoptrack_closings_seller_insert on public.daily_closings;
drop policy if exists shoptrack_closings_seller_update_today on public.daily_closings;

create policy shoptrack_closings_seller_insert
on public.daily_closings
for insert to authenticated
with check (public.is_shop_member(shop_id));

-- La modification est bornée au JOUR MÊME.
--
-- Rouvrir puis refermer une journée en cours est un geste normal — on recompte
-- parce qu'on s'est trompé. Réécrire une clôture passée ne l'est pas : ce
-- serait effacer un écart déjà constaté, et c'est exactement ce que le mode
-- Patron protège depuis le début.
create policy shoptrack_closings_seller_update_today
on public.daily_closings
for update to authenticated
using (
  public.is_shop_member(shop_id)
  and closing_date >= (now() at time zone 'Africa/Douala')::date
)
with check (
  public.is_shop_member(shop_id)
  and closing_date >= (now() at time zone 'Africa/Douala')::date
);
