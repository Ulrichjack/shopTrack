-- Laisser passer les envois de caisse et de clôture.
--
-- Deux erreurs de ma part, le même jour, sur la même migration.
--
-- PREMIÈRE : l'application envoie les mouvements de caisse et les clôtures par
-- `upsert`, jamais par un simple insert. PostgreSQL, devant un
-- `INSERT ... ON CONFLICT DO UPDATE`, exige que la politique UPDATE existe —
-- même quand la ligne est nouvelle et que le chemin d'update ne sert pas. Je
-- n'avais posé que l'INSERT, et tout se faisait refuser avec « Accès refusé
-- par le serveur ».
--
-- SECONDE : j'avais borné la modification d'une clôture au JOUR MÊME, pour
-- qu'un écart déjà constaté ne puisse pas être réécrit. L'intention était
-- bonne, l'effet catastrophique : elle interdisait la CLÔTURE EN RETARD, que
-- l'application propose explicitement et qui est le cas courant d'un
-- commerçant qui a sauté trois jours.
--
-- Une règle qui empêche le geste normal pour prévenir un geste rare n'est pas
-- une protection, c'est une panne.
--
-- Ce qui protège réellement l'historique tient ailleurs, et tient déjà :
-- le vendeur ne voit ni le bilan mensuel ni le rapport de période, une clôture
-- refermée ajoute sa note à la précédente au lieu de l'effacer, et chaque
-- écart reste inscrit dans sa ligne.

drop policy if exists shoptrack_closings_seller_update_today on public.daily_closings;
drop policy if exists shoptrack_cash_seller_update on public.cash_movements;
drop policy if exists shoptrack_closings_seller_update on public.daily_closings;

create policy shoptrack_cash_seller_update
on public.cash_movements
for update to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));

create policy shoptrack_closings_seller_update
on public.daily_closings
for update to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));
