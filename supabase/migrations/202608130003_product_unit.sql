-- Unité de mesure d'un produit : sac, bouteille, casier, pack, boîte,
-- sachet, g, l… ou rien du tout.
--
-- Simple étiquette d'affichage : elle n'entre dans aucun calcul, contrairement
-- aux unités du module A (product_units) qui portent un ratio de conversion.
-- Ici l'épicier compte dans une seule unité par produit — celle dans laquelle
-- il compte — donc aucune conversion n'est nécessaire.
--
-- Nullable : les produits existants et le mode simple ne sont pas concernés.

alter table public.products
  add column if not exists unit text;
