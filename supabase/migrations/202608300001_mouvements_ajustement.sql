-- Accepter les mouvements d'ajustement de caisse.
--
-- La caisse continue enregistre un ajustement chaque fois que le montant
-- réellement compté diffère du calcul : c'est ce qui permet au solde de repartir
-- du chiffre constaté sans réécrire la clôture passée.
--
-- L'application produisait déjà `adjustment_in` et `adjustment_out`, mais la
-- contrainte de la table ne connaissait que trois types. Chaque ajustement
-- partait donc, se faisait refuser cinq fois, et finissait mis de côté avec le
-- bandeau « opération refusée par le serveur ».
--
-- Le garde-fou a bien travaillé — rien n'a été perdu, rien n'est parti faux —
-- mais le commerçant voyait une erreur rouge sans comprendre pourquoi. Relevé
-- le 30/08/2026 sur une clôture avec un écart de 2 500 F.
--
-- ⚠️ La leçon dépasse ce cas : un type ajouté côté Dart n'existe pas tant que
-- la contrainte ne le connaît pas. Les deux vocabulaires doivent bouger
-- ensemble, dans la même livraison.

alter table public.cash_movements
  drop constraint if exists cash_movements_type_check;

alter table public.cash_movements
  add constraint cash_movements_type_check
  check (
    type = any (
      array[
        -- Le fonds saisi le matin. Conservé pour l'historique : la caisse
        -- continue ne le demande plus, mais les anciennes lignes existent.
        'morning_balance',
        'withdrawal',
        'incoming',
        -- Écart constaté à un comptage réel. Le signe vit dans le type, jamais
        -- dans le montant : `amount` reste positif partout ailleurs dans la
        -- table, et une valeur négative fausserait toutes les sommes.
        'adjustment_in',
        'adjustment_out'
      ]::text[]
    )
  );
