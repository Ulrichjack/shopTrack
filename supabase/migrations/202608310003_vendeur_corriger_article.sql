-- Laisser le vendeur corriger une fiche produit.
--
-- Il peut créer un article — la marchandise arrive quand elle arrive — mais
-- pas en corriger le nom. Une faute de frappe au moment de la création restait
-- donc définitive jusqu'au passage de la propriétaire. C'est le genre de
-- blocage qui pousse à contourner l'application.
--
-- L'écran de modification était DÉJÀ prévu pour lui : le champ prix d'achat
-- n'apparaît qu'en mode Patron, et l'enregistrement conserve la valeur
-- existante au lieu de l'écraser. Seules la route et cette politique
-- bloquaient.
--
-- Ce qu'il peut donc changer : le nom, l'unité, le code-barres, la photo, le
-- seuil d'alerte, et le prix de VENTE. Ce dernier mérite un mot : il peut déjà
-- négocier n'importe quel prix au moment de la vente, et tout changement de
-- tarif laisse une trace datée dans `product_prices`. Le lui interdire ici
-- n'empêcherait rien tout en l'empêchant de corriger une erreur.
--
-- Ce qu'il ne voit ni ne change : le prix d'ACHAT, donc la marge.
--
-- La suppression, elle, reste fermée — et avec elle l'archivage, qu'elle
-- propose devant un produit qui a une histoire. Ranger un article attend très
-- bien le retour de la propriétaire.

drop policy if exists shoptrack_products_seller_update on public.products;

create policy shoptrack_products_seller_update
on public.products
for update to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));
