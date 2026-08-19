-- Un transfert doit dire D'OÙ il vient et OÙ il va, en toutes lettres.
--
-- `from_shop_id` et `to_shop_id` ne sont lisibles que par quelqu'un qui est
-- membre des deux boutiques. Un vendeur ne l'est jamais : il appartient à une
-- seule. Les règles RLS le lui interdisent, et c'est voulu — un vendeur n'a
-- pas à consulter les autres boutiques de son patron.
--
-- Résultat constaté le 19/08/2026 : un vendeur de « Mode b2 » voyait
-- « De Autre boutique » sur toute sa marchandise reçue, sans jamais pouvoir
-- savoir qui la lui envoyait. Le patron, lui, ne voyait rien d'anormal :
-- membre des trois boutiques, tous les noms se résolvaient chez lui.
--
-- Même remède que product_name la veille : ce que le destinataire ne peut pas
-- aller chercher, le transfert le lui apporte. Le nom est figé à l'envoi,
-- ce qui est aussi plus juste — renommer une boutique ne doit pas réécrire
-- l'historique des transferts déjà reçus.
--
-- Nullable : les transferts déjà enregistrés n'ont pas cette information.

alter table public.stock_transfers
  add column if not exists from_shop_name text,
  add column if not exists to_shop_name text;
