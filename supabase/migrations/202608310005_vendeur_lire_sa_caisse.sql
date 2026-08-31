-- Laisser le vendeur LIRE la caisse et les clôtures de sa boutique.
--
-- Sans ce droit, il ne peut pas clôturer du tout : l'application envoie la
-- clôture par `upsert`, et PostgreSQL applique les politiques de LECTURE à la
-- ligne en conflit avant de décider s'il l'écrase. Écriture autorisée, lecture
-- refusée : l'opération échoue.
--
-- Et clôturer n'est pas optionnel ici. La propriétaire de cette boutique passe
-- toutes les quelques semaines : si elle seule peut compter le tiroir, il n'est
-- jamais compté, et l'écart réel n'apparaît jamais. Le contrôle qu'on croyait
-- protéger n'existait déjà plus.
--
-- ⚠️ CE QUE ÇA CONCÈDE, ET IL FAUT LE DIRE.
--
-- Les lignes de clôture portent `gross_profit` et `net_profit`. RLS filtre des
-- LIGNES, pas des COLONNES : donner la lecture, c'est donner ces deux nombres
-- à qui interroge le serveur directement. L'application, elle, ne les affiche
-- pas — le bilan mensuel et le rapport de période restent fermés au vendeur.
--
-- C'est donc le même arbitrage que pour `products.buy_price` : un rideau, pas
-- une serrure. La menace réelle est « le vendeur regarde son écran », pas
-- « le vendeur écrit une requête HTTP ». Fermer vraiment ces colonnes demande
-- une vue dédiée, et se paiera d'une refonte du téléchargement.
--
-- À faire le jour où ce n'est plus acceptable, pas avant : une boutique qui ne
-- clôture jamais coûte plus cher qu'un bénéfice lisible par quelqu'un qui
-- devrait de toute façon savoir si sa journée s'est bien passée.

drop policy if exists shoptrack_closings_member_read on public.daily_closings;
drop policy if exists shoptrack_cash_member_read on public.cash_movements;

create policy shoptrack_closings_member_read
on public.daily_closings
for select to authenticated
using (public.is_shop_member(shop_id));

-- Même raison : les mouvements partent aussi par `upsert`, et le vendeur doit
-- pouvoir relire les sorties qu'il a lui-même enregistrées.
create policy shoptrack_cash_member_read
on public.cash_movements
for select to authenticated
using (public.is_shop_member(shop_id));
