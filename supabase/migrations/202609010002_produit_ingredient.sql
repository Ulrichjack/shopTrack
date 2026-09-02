-- Marquer un produit comme matière première.
--
-- La farine, le beurre, le tissu et la peinture entrent dans le stock avec leur
-- prix d'achat : c'est ce qui permettra de chiffrer ce qu'une commande a coûté.
-- Mais ils ne se vendent pas au comptoir.
--
-- Sans cette marque, une trentaine d'ingrédients viendraient s'intercaler dans
-- l'écran de vente entre deux articles que la cliente peut réellement acheter —
-- et on choisirait « Farine » à la place de « Farine Scarlet 1 kg » un soir de
-- presse.
--
-- Purement additif : la colonne a une valeur par défaut, aucun produit existant
-- ne change de comportement, et aucune requête existante n'a besoin d'être
-- réécrite.

alter table public.products
  add column if not exists is_ingredient boolean not null default false;

comment on column public.products.is_ingredient is
  'Matière première : entre dans le coût d''une commande, ne se vend pas au comptoir.';
