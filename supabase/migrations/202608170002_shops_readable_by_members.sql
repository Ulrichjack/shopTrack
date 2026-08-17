-- Un membre doit pouvoir lire la boutique où il travaille.
--
-- Trace relevée sur le téléphone d'un vendeur :
--
--   [SHOPS] réponse brute : [{shop_id: 0ae2fedd…, role: seller, shops: null}]
--
-- `shops: null` : la jointure ne renvoie rien. La policy de `shops` n'autorise
-- que le propriétaire, si bien qu'un vendeur ne voit jamais le nom de sa
-- propre boutique — l'app affiche « Ma boutique », sa valeur de repli.
--
-- Lire le nom de la boutique où l'on travaille n'expose rien : ni chiffre, ni
-- stock, ni prix. Les données métier restent protégées par leurs propres
-- policies, qui passent déjà par `is_shop_member`.
--
-- Policy en lecture seule et en plus des existantes (les policies permissives
-- se cumulent en OU) : personne ne gagne le droit de modifier une boutique.

drop policy if exists shoptrack_shops_member_read on public.shops;
create policy shoptrack_shops_member_read
on public.shops
for select
to authenticated
using (public.is_shop_member(id));
