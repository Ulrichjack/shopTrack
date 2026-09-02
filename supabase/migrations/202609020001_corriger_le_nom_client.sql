-- Laisser corriger le nom d'une cliente.
--
-- Un nom mal entendu au téléphone est l'erreur la plus courante du module, et
-- la plus gênante : ce nom se lit dans la liste des commandes, dans le journal
-- de caisse et dans le bilan. Sans ce droit, la seule issue était de recréer
-- la commande — en perdant ses acomptes.
--
-- Ouvert au membre, parce que c'est LUI qui a pris l'appel et mal entendu.
-- Attendre la propriétaire pour réparer une faute de frappe, c'est laisser le
-- nom faux sur tous les écrans en attendant.
--
-- La table `clients` avait `owner_all`, `member_read` et `member_insert` — mais
-- aucune mise à jour pour le membre. Le défaut ne se voyait pas : l'écran
-- écrivait en local sans broncher, et le refus ne serait apparu qu'au moment
-- de la synchronisation, des heures plus tard.

drop policy if exists shoptrack_clients_member_update on public.clients;
create policy shoptrack_clients_member_update
on public.clients
for update to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));
