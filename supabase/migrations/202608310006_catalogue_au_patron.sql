-- Rendre le catalogue au patron.
--
-- Créer et modifier un produit ont été ouverts au vendeur quelques heures plus
-- tôt le même jour, puis refermés. La raison mérite d'être gardée, parce
-- qu'elle a l'air de se contredire.
--
-- On les avait ouverts pour que la marchandise arrivée le matin soit vendable
-- tout de suite. Mais la cliente a tranché : le stock reste au patron. Créer
-- un article que le vendeur ne peut pas approvisionner ne lui sert donc à
-- rien — il obtient une fiche à zéro, invendable, et le geste ne fait
-- qu'ajouter des lignes incomplètes au catalogue.
--
-- Et sans création, il n'y a plus de faute de frappe à réparer : l'argument
-- qui justifiait la modification tombe avec.
--
-- Le rôle tient désormais dans la phrase de la cliente : « elle vend ». Tout
-- ce qui n'est ni vendre, ni faire tomber la caisse juste, appartient au
-- patron.
--
-- Ce qui reste ouvert au vendeur, et pourquoi :
--   vendre, lire le catalogue        il doit savoir quoi servir et à quel prix
--   sortie de caisse, remise         sinon la caisse est fausse et on l'accuse
--   clôturer                         sinon le tiroir n'est jamais compté
--   signaler une casse               sinon la perte devient un manquant
--   recevoir un transfert            son seul réapprovisionnement possible

drop policy if exists shoptrack_products_seller_insert on public.products;
drop policy if exists shoptrack_products_seller_update on public.products;
