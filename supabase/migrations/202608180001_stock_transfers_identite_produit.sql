-- Un transfert doit dire CE QU'IL TRANSPORTE.
--
-- `stock_transfers.product_id` désigne la fiche produit de la boutique
-- EXPÉDITRICE. Or un produit n'appartient qu'à une seule boutique
-- (`products.shop_id`) : la boutique qui reçoit n'a donc aucune ligne pour
-- cet identifiant, et son téléchargement ne la lui donnera jamais puisqu'il
-- filtre par boutique active.
--
-- Deux conséquences, constatées le 18/08/2026 sur deux appareils :
--   * la liste des transferts affiche « Produit inconnu » ;
--   * surtout, la RÉCEPTION abandonne en silence — elle a besoin du nom, du
--     prix et de l'unité pour retrouver ou créer l'article jumeau, et n'a
--     rien. La marchandise n'arrive jamais, aucun message ne le signale.
--
-- Le remède est celui que `sale_items` applique depuis toujours : recopier
-- l'identité du produit dans la ligne. Une ligne de vente garde son
-- `product_name`, son `buy_price` et son `sell_price` pour qu'un bilan reste
-- lisible même si le produit est renommé ou archivé. Un transfert a le même
-- besoin, et en plus une bonne raison comptable : le prix retenu doit être
-- celui du jour de l'envoi, pas celui d'aujourd'hui.
--
-- Nullable : les transferts déjà enregistrés n'ont pas cette information et
-- ne peuvent pas l'inventer.

alter table public.stock_transfers
  add column if not exists product_name text,
  add column if not exists buy_price numeric,
  add column if not exists sell_price numeric,
  add column if not exists unit text;
