# Le schéma de la base ShopTrack

Dix-neuf tables, relevées sur Supabase le 21/08/2026. La base locale (Drift)
porte les mêmes tables avec les mêmes colonnes, préfixées `Local` — c'est
volontaire : une donnée doit pouvoir descendre et remonter sans traduction.

Un seul diagramme de dix-neuf tables serait illisible. Elles sont donc
regroupées par domaine, dans l'ordre où on les rencontre en lisant le code.

---

## 1. Le noyau — ce qui existe dans les trois modes

```mermaid
erDiagram
    shops ||--o{ shop_members : "qui y a accès"
    shops ||--|| shop_settings : "quel mode"
    shops ||--o{ products : "son catalogue"
    products ||--o{ product_prices : "l'historique des tarifs"
    products ||--o{ product_units : "ses conditionnements"

    shops {
        uuid id PK
        uuid owner_id "le créateur"
        text name
    }
    shop_members {
        uuid id PK
        uuid shop_id FK
        uuid user_id
        text role "owner | seller"
    }
    shop_settings {
        uuid shop_id PK "une ligne par boutique"
        text unit_mode "simple | hierarchical"
        text sale_capture_mode "realtime | periodic"
        bool multi_point_enabled
    }
    products {
        uuid id PK
        uuid shop_id FK
        text name
        numeric buy_price "tarif ACTUEL"
        numeric sell_price "tarif ACTUEL"
        int quantity
        int min_quantity "seuil d'alerte"
        text unit
        timestamptz archived_at "rangé, jamais supprimé"
    }
    product_prices {
        uuid id PK
        uuid product_id FK
        numeric buy_price
        numeric sell_price
        timestamptz effective_at "à partir de quand"
    }
    product_units {
        uuid id PK
        uuid product_id FK
        text unit_name "plaquette, carton..."
        int ratio_to_base "30 œufs dans une plaquette"
    }
```

**`shop_settings` décide de tout.** Deux interrupteurs, quatre combinaisons —
mais seules trois sont utilisées : vente simple, cycles (`hierarchical`),
inventaire (`periodic`). C'est cette ligne que lit `_HomeForShopMode` pour
choisir quel accueil construire.

**`products.buy_price` et `sell_price` sont les tarifs du jour**, pas ceux du
passé. Le passé vit dans `product_prices`, avec sa date d'entrée en vigueur.
Sans cette table, changer un prix réécrirait tous les bilans déjà consultés.

**`archived_at` remplace la suppression.** Un produit qui a servi ne se supprime
pas : les rapports de périodes closes le citent encore. On l'archive, il
disparaît du stock, du comptage et de la vente — son histoire reste.

---

## 2. Vente simple — la vente est enregistrée à l'instant

```mermaid
erDiagram
    shops ||--o{ sales : ""
    sales ||--o{ sale_items : "le détail"
    products ||--o{ sale_items : ""
    product_units ||--o{ sale_items : "vendu en quelle unité"
    shops ||--o{ cash_movements : "fonds et retraits"
    shops ||--o{ daily_closings : "une par journée"

    sales {
        uuid id PK
        uuid shop_id FK
        uuid user_id "qui a vendu"
        numeric total_amount
        numeric total_profit
        timestamptz created_at
    }
    sale_items {
        uuid id PK
        uuid sale_id FK
        uuid product_id FK
        text product_name "COPIE, pas une référence"
        int quantity
        numeric sell_price "FIGÉ à la vente"
        numeric buy_price "FIGÉ à la vente"
        numeric profit "FIGÉ à la vente"
        uuid unit_id FK
        int quantity_in_base
        uuid cycle_id FK "si mode cycles"
    }
    cash_movements {
        uuid id PK
        uuid shop_id FK
        numeric amount
        text type "morning_balance | withdrawal"
        text category
    }
    daily_closings {
        uuid id PK
        uuid shop_id FK
        date closing_date "UNIQUE avec shop_id"
        numeric morning_balance
        numeric total_sales
        numeric total_withdrawals
        numeric calculated_cash "attendu en caisse"
        numeric physical_cash "compté à la main"
        numeric cash_gap "l'écart"
        bool is_closed
        text note
    }

```

**`sale_items` copie tout au lieu de référencer.** Le nom, les deux prix et le
bénéfice sont écrits au moment de la vente. Changer le tarif demain ne touche
donc aucune vente d'hier — c'est un fait daté, pas une vue sur la fiche.

**`daily_closings` est unique par `(shop_id, closing_date)`.** Une journée ne se
clôture qu'une fois ; refermer après réouverture met à jour la même ligne et
conserve la note précédente.

**`calculated_cash` = fonds du matin + ventes − retraits.** L'écart avec
`physical_cash` est le chiffre que le patron regarde en premier.

---

## 3. Cycles — le bilan par arrivage

```mermaid
erDiagram
    shops ||--o{ supply_cycles : ""
    products ||--o{ supply_cycles : "un cycle ouvert à la fois"
    supply_cycles ||--o{ cycle_losses : "la casse"
    supply_cycles ||--o{ sale_items : "les ventes du cycle"

    supply_cycles {
        uuid id PK
        uuid shop_id FK
        uuid product_id FK
        int quantity_received "en unité de BASE"
        numeric purchase_cost "le total payé"
        numeric reference_margin_per_unit "gain espéré, optionnel"
        text status "open | closed"
        timestamptz opened_at
        timestamptz closed_at
    }
    cycle_losses {
        uuid id PK
        uuid cycle_id FK
        int quantity
        text reason
    }
```

**Le coût unitaire n'est pas stocké : il se recalcule.** `purchase_cost ÷
quantity_received`. Tes 135 000 F pour 900 œufs donnent 150 F, et ce 150 ne
dépend d'aucun tarif de fiche. Modifier le prix d'achat du produit ne touche
donc aucun cycle passé.

**`reference_margin_per_unit` fabrique le prix de vente.** Gain espéré déclaré
à l'arrivage → l'app propose `(coût + gain) ÷ quantité × contenance`. C'est
l'inverse de la démarche habituelle, et c'est celle du commerçant : « j'ai payé
135 000, je veux gagner 45 000 dessus ».

**Un seul cycle ouvert par produit.** Un deuxième arrivage par-dessus le
premier rendrait invendable le reliquat du précédent — l'app le refuse.

---

## 4. Inventaire — les ventes se déduisent, elles ne se saisissent pas

```mermaid
erDiagram
    shops ||--o{ inventory_counts : "les repères"
    products ||--o{ inventory_counts : ""
    shops ||--o{ inventory_losses : "la casse déclarée"
    products ||--o{ inventory_losses : ""
    shops ||--o{ shop_takings : "la recette du jour"
    products ||--o{ stock_purchases : "les arrivages"

    inventory_counts {
        uuid id PK
        uuid shop_id FK
        uuid product_id FK
        timestamptz counted_at
        int counted_quantity
        timestamptz previous_counted_at "le repère d'avant"
        int previous_quantity
    }
    inventory_losses {
        uuid id PK
        uuid shop_id FK
        uuid product_id FK
        int quantity
        text reason
        timestamptz occurred_at "le jour de la casse"
    }
    shop_takings {
        uuid id PK
        uuid shop_id FK
        date date
        numeric amount
    }
    stock_purchases {
        uuid id PK
        uuid shop_id FK
        uuid product_id FK
        int quantity
        numeric unit_cost "le prix payé CE jour-là"
        timestamptz purchased_at "date de RÉCEPTION"
    }
```

**Chaque comptage porte le précédent.** `previous_counted_at` et
`previous_quantity` sont écrits en dur dans la ligne : une période se lit sans
requête sur les autres lignes. C'est ce qui rend le rapport rapide — et c'est
aussi pourquoi on ne peut pas insérer un comptage antérieur après coup.

**Le calcul central :**

```
sorties  = stock d'ouverture + arrivages + transferts reçus
           − transferts envoyés − stock compté
vendus   = sorties − pertes déclarées
```

**`stock_purchases.purchased_at` est la date de réception**, pas celle de la
saisie. Une livraison du lundi notée le mercredi appartient à la période du
lundi. Le rapport lit cette table et non `stock_movements`, dont la date est
celle de l'envoi au serveur.

**Le prix de vente d'une période est pondéré par les jours.** L'app parcourt
chaque jour de la période et retient le tarif en vigueur ce jour-là, d'après
`product_prices`. Un tarif changé après la clôture porte une date postérieure :
il n'est jamais retenu, la période close ne bouge pas.

---

## 5. Transferts entre boutiques

```mermaid
erDiagram
    shops ||--o{ stock_transfers : "expéditrice"
    shops ||--o{ stock_transfers : "destinataire"
    products ||--o{ stock_transfers : ""

    stock_transfers {
        uuid id PK
        uuid from_shop_id FK
        uuid to_shop_id FK
        uuid product_id FK "la fiche de l'EXPÉDITEUR"
        text product_name "copié à l'envoi"
        numeric buy_price "copié à l'envoi"
        numeric sell_price "copié à l'envoi"
        text unit "copié à l'envoi"
        text from_shop_name "copié à l'envoi"
        text to_shop_name "copié à l'envoi"
        int quantity "envoyé"
        int received_quantity "réellement arrivé"
        timestamptz received_at "null = pas encore reçu"
        timestamptz cancelled_at
    }
```

**Tout est copié dans la ligne de transfert.** Le nom, les prix, l'unité, les
deux noms de boutique. Ce n'est pas de la redondance paresseuse : le
destinataire n'a **jamais téléchargé** la fiche produit de l'expéditeur — le
pull filtre par boutique active. Sans ces copies, une réception depuis une
boutique jamais ouverte sur l'appareil échouait en silence.

**`received_at` sert de garde.** Confirmer deux fois créditait le stock deux
fois : six bidons envoyés, douze sur l'étagère, et rien dans la table pour le
trahir. Une réception déjà datée est désormais refusée.

**Les noms de boutique sont figés à l'envoi**, volontairement : un reçu ne se
réécrit pas parce que l'enseigne a changé.

---

## 6. Synchronisation

```mermaid
erDiagram
    shops ||--o{ stock_movements : "l'historique du stock"
    products ||--o{ stock_movements : ""
    shops ||--o{ stock_sync_operations : "le garde-fou"

    stock_movements {
        uuid id PK
        uuid shop_id FK
        uuid product_id FK
        int quantity
        text type "recharge | transfer_in | ..."
        timestamptz created_at
    }
    stock_sync_operations {
        uuid id PK "= l'id du mouvement"
        uuid shop_id FK
        uuid product_id FK
        int quantity_delta
        text operation_type
    }
```

**`stock_sync_operations` empêche d'appliquer deux fois le même mouvement.** La
fonction serveur `apply_stock_movement` y insère l'opération avec son
identifiant ; si la ligne existe déjà, elle rend le stock courant sans rien
retoucher. Un réseau qui coupe au retour peut donc renvoyer l'opération sans
danger.

**La file d'attente n'existe qu'en local** (`sync_queue`, table Drift). Elle ne
monte jamais sur le serveur : c'est la liste de ce qui n'est pas encore parti.

---

## Les trois règles à ne jamais oublier

**Toute table synchronisée se déclare dans `tablesTirees`**
(`lib/core/sync/pull_registry.dart`). Une colonne oubliée là et le
téléchargement réécrit la ligne locale sans elle — la donnée disparaît
quelques secondes après sa création, invisible sur un seul téléphone.

**Toute lecture locale filtre par `shop_id`.** Le pull fusionne sans jamais
vider : la base locale garde les données de chaque boutique visitée. Sans
filtre, deux boutiques se mélangent — et une écriture peut partir avec
l'identité d'une autre.

**Toute date envoyée au serveur passe par `.toUtc()`.** Une heure locale sans
fuseau est rangée comme universelle, et une vente de 23 h se retrouve au
lendemain, donc dans la mauvaise clôture.
