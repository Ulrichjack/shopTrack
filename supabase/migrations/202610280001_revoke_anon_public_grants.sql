-- Les données de boutique n'ont aucun usage public avant connexion.
-- Les policies RLS sont déjà réservées à authenticated ; retirer aussi les
-- grants anon évite qu'une future policy mal définie expose ces objets.
-- Inclut la vue dossiers_commandes_avec_solde (security_invoker=true).
revoke all privileges on all tables in schema public from anon;
