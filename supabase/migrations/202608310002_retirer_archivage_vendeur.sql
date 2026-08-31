-- Retirer la fonction d'archivage ouverte au vendeur.
--
-- Écrite quelques heures plus tôt le même jour, puis abandonnée : archiver un
-- produit est une décision de CATALOGUE, et elle attend très bien le retour de
-- la propriétaire.
--
-- La règle qui a tranché : le vendeur peut faire ce qui NE PEUT PAS ATTENDRE.
-- Créer un article — la marchandise est là, il faut la vendre. Sortir de
-- l'argent — sinon le tiroir ne tombe plus juste le soir et le manquant lui
-- est attribué. Clôturer — c'est lui qui compte en fermant. Ranger un produit
-- qu'on ne vend plus, non.
--
-- Le bouton est donc simplement masqué dans la fiche produit, et l'archivage
-- repasse par un `UPDATE_PRODUCT` ordinaire réservé au patron. Moins de
-- surface serveur pour le même résultat.

drop function if exists public.basculer_archivage_produit(uuid, boolean);
