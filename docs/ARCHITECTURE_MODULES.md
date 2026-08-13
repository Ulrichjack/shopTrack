# Architecture — Modules métier custom (2026-08-08)

> Ce document décrit l'architecture pour intégrer deux besoins clients (œufs/cycles,
> multi-point/inventaire) dans ShopTrack **en tant que modules optionnels par boutique**,
> sans casser le flux existant (vente immédiate, boutique unique). Le plan d'implémentation
> (ordre des étapes) est un document séparé, à écrire une fois cette architecture validée.

## 0. Principe directeur

ShopTrack reste le socle commun : auth, notion de boutique (`shops`/`shop_members`,
déjà multi-boutique côté RLS via `is_shop_member(shop_id)`), sync engine, `Product`
simple, vente immédiate. Les deux besoins deviennent des **capacités activables par
boutique**, pas une réécriture du cœur ni des apps séparées.

```
shop_settings (nouvelle table Supabase, 1 ligne par boutique)
├── unit_mode: 'simple' | 'hierarchical'          → Module A (cycles/unités)
├── sale_capture_mode: 'realtime' | 'periodic'    → Module B (multi-point/inventaire)
└── multi_point_enabled: bool                     → Module B
```

Chargé une fois au login, mis en cache localement (table Drift `LocalShopSettings`),
exposé par un provider Riverpod (`shopSettingsProvider`). Le router et les écrans
lisent ce provider pour afficher/masquer les nouveaux écrans — même mécanisme que
`bossModeAccess` aujourd'hui pour les routes Patron.

**Pourquoi pas un flag global par build** : deux boutiques peuvent tourner sur la même
app (même APK) avec des configs différentes ; un flag de compilation obligerait un
APK par client.

## 1. Module A — Cycles d'approvisionnement & unités (client œufs)

Généralisé : pas de code spécifique "œuf", tout est piloté par des unités et ratios
définis par produit. Réutilisable pour tout produit vendu en vrac avec conversion
(sacs de riz, casiers de boissons, etc.).

### Nouvelles entités

- **`product_units`** : `id, product_id, unit_name, ratio_to_base, sort_order`.
  L'unité de base a `ratio_to_base = 1`. Exemple œufs : `œuf(1), plateau(30),
  carton(360)`. N niveaux, pas limité à 3.
- **`supply_cycles`** : `id, shop_id, product_id, opened_at, closed_at, quantity_received
  (unité de base), purchase_cost (coût réel total), reference_margin_per_unit (le
  "gain de référence par carton", nullable — affichage rapide seulement), status`.
- **`cycle_losses`** : `id, cycle_id, quantity (unité de base), reason (enum: casse,
  rongeurs, deterioration, autre), note, created_at`.
- **Extension des lignes de vente** (`sale_items`) : `cycle_id (nullable)`,
  `unit_id (nullable, référence product_units)`, `quantity_in_base (calculée)`,
  `unit_sell_price (prix réellement pratiqué sur cette ligne)`. Le prix réel par ligne
  est ce qui permet des marges différentes par client/quantité (besoin §4 du client) —
  le "gain théorique par carton" ne sert qu'à préremplir/afficher, jamais au calcul
  comptable final.

### Calcul (fonction pure, même pattern que `daily_cash_calculator.dart`)

Nouveau fichier `lib/core/utils/cycle_result_calculator.dart` :

```
coût_unitaire_réel   = purchase_cost / quantity_received
chiffre_affaires     = Σ (quantity_in_base × unit_sell_price) sur les ventes du cycle
coût_stock_vendu     = Σ (quantity_in_base vendue) × coût_unitaire_réel
valeur_pertes        = Σ (quantity perdue) × coût_unitaire_réel
stock_restant        = quantity_received − Σ vendu(base) − Σ perdu(base)
bénéfice_net_cycle   = chiffre_affaires − coût_stock_vendu − valeur_pertes
```

Le "gain théorique par carton/plateau/œuf" du client (règle de 3 sur
`reference_margin_per_unit`) reste un **affichage secondaire** dans l'écran de vente
(aide à la saisie du prix), jamais la source du bénéfice net rapporté en fin de cycle —
conforme à la recommandation du client lui-même (§11 de son besoin).

### Écrans/dossier

`lib/features/cycles/` (data/domain/presentation, même structure que les autres
features) : création de cycle, saisie de perte, écran vente adapté (sélecteur d'unité
+ conversion live), rapport de cycle.

## 2. Module B — Multi-point de vente & inventaire périodique (2e client)

> **Révisé le 2026-08-13** après échange direct avec le client. Le modèle
> ci-dessous remplace la première version (formule simple `stock initial +
> entrées − restant`), qui était fausse dès qu'il existe des transferts.

### Ce que le client fait, dans ses mots

Il tient une épicerie sur **3 points de vente** (pain, jus, mayonnaise, sucre,
riz). Il **ne peut pas saisir ses ventes** : pas le temps, trop de pression.
Il note **la recette totale de chaque journée**, et **compte tout son stock**
en fin de mois ou de trimestre. Il veut que l'app lui dise ce qui a été vendu
et s'il a gagné.

### Décisions verrouillées avec lui

| Sujet | Décision |
|-------|----------|
| Fréquence d'inventaire | **Libre** : la période court d'un comptage au suivant, pas de mois imposé |
| Étendue du comptage | Il compte **tous** ses produits → un résultat global est fiable |
| Unité de suivi | **Par produit** : mayonnaise en cartons, riz en sacs, jus en bouteilles |
| Prix d'achat | **Dernier prix connu** (il revalorise au prix du marché) — ni FIFO ni coût moyen |
| Recette | Notée **par boutique**, sinon le bénéfice par boutique est impossible |
| Vente à crédit | **Non gérée** : ce qui sort est considéré comme vendu |
| Consommation personnelle | Sortie ordinaire, comptée comme vendue |
| Transferts | Stock déplacé **immédiatement** des deux côtés ; vérification à l'arrivée facultative, l'écart devient une perte de transport |

### Unités : réception ≠ comptage ≠ base

Trois rôles distincts, souvent confondus :

- **unité de base** = la plus petite chose qu'il vend (bouteille) — on peut
  toujours monter vers le casier, jamais descendre depuis le casier ;
- **unité de réception** = comment il achète (palette de 600) ;
- **unité de comptage** = comment il compte (casier de 12).

C'est exactement `product_units` du **module A**, réutilisé tel quel. Les deux
modules partagent donc la couche de conversion — le module A a construit la
fondation du module B sans que ce soit prévu.

### Le calcul, en quatre niveaux

Un comptage ne distingue **jamais** une vente d'un vol : il dit seulement que
la marchandise n'est plus là. D'où la séparation :

```
Stock au dernier comptage          500
+ Achats de la période            +300
+ Transferts reçus                 +50
− Transferts envoyés              −100
− Stock compté aujourd'hui        −180
─────────────────────────────────────
= SORTIES TOTALES                  570     ← parti, sans savoir pourquoi
− Pertes déclarées (casse, pain)   −20
─────────────────────────────────────
= VENTES PRÉSUMÉES                 550     ← présumées, jamais certaines
```

Puis le croisement avec l'argent, qui est **l'apport réel de l'app** :

```
550 × prix de vente          = 275 000 F   ← ce qu'il aurait dû encaisser
Recettes notées              = 269 000 F   ← ce qu'il a encaissé
─────────────────────────────────────────
ÉCART INEXPLIQUÉ             =  −6 000 F   ⚠️
```

Ce dernier chiffre est ce qu'il ne peut pas voir aujourd'hui. L'app ne dit pas
« tu as été volé », elle dit « 6 000 F ne s'expliquent pas ». C'est la
**démarque inconnue** du commerce de détail, nommée au lieu d'être noyée dans
« ventes ».

Bénéfice = recettes encaissées − coût d'achat des sorties.

### Nouvelles entités

- **`shop_takings`** : `id, shop_id, date, amount` — la recette du jour, par
  boutique. Une seule saisie quotidienne, c'est toute la charge demandée.
- **`inventory_counts`** : `id, shop_id, product_id, counted_at,
  counted_quantity, previous_count_at, previous_quantity` — un point de repère
  par produit. On ne reconstitue jamais le passé : **on pose des repères**.
- **`stock_transfers`** : `id, from_shop_id, to_shop_id, product_id, quantity,
  transferred_at, received_quantity (nullable), created_by`.
- **Mouvements typés** : `purchase | transfer_in | transfer_out | loss`.

### Comptage à l'aveugle (règle d'interface)

Pendant la saisie, **ne jamais afficher la quantité théorique**. Sinon il
confirme le chiffre proposé au lieu de compter, et l'inventaire ne vaut plus
rien. L'écart ne s'affiche **qu'après** validation.

Le comptage se sauvegarde au fur et à mesure et peut s'étaler sur plusieurs
jours (il n'est pas toujours sur place) : l'app affiche « 22 produits sur 30 »
et ne calcule le résultat global qu'une fois tout compté.

### Multi-boutique

Un compte, 3 boutiques, un sélecteur en haut d'écran. **Pas de hiérarchie** :
le rapport global est la somme des boutiques. Chaque boutique a son stock, ses
recettes, ses inventaires — donc son bénéfice propre, ce qui est justement ce
que le client ne peut pas voir aujourd'hui.

Le schéma Supabase le permet déjà (`shop_members` est un lien N-N). Le travail
est **côté client** : `sync_service.dart` ne prend que la première boutique
trouvée (`...single()`). C'est la plus grosse partie du module.

### Écrans

`lib/features/inventory/` : sélecteur de boutique, saisie de la recette du
jour, saisie de transfert, comptage, rapport par boutique et consolidé.

### Différence de nature avec le module A

Le module A **s'ajoute** (par produit, cumulable). Le module B **remplace** le
mode de saisie (par boutique, exclusif) : si une boutique mélangeait les deux,
les ventes déjà enregistrées seraient recomptées dans l'estimation. Bascule
possible seulement entre deux périodes closes.

### Concurrence (relevé du 2026-08-13)

FlustockX, iZi Depo, KABRAK, Avobi couvrent le marché camerounais — tous en
**saisie temps réel**, exactement ce que ce client refuse. La dette client est
leur fonctionnalité phare ; on ne la fait pas (décision client). Le partage
WhatsApp d'un bilan est la seule idée à reprendre à court terme.

## 3. Ce qui NE change PAS

- Le modèle `Product`/`Sale` simple actuel reste le chemin par défaut
  (`unit_mode: simple`, `sale_capture_mode: realtime`) pour toute boutique qui n'a
  besoin d'aucun des deux modules — aucune régression pour les testeurs bêta actuels.
- Le moteur de sync (`processQueue` → `pullDataFromSupabase` si file vide) est réutilisé
  tel quel ; les nouvelles tables suivent le même pattern (file locale → RPC/upsert →
  merge, jamais de suppression locale avant remplissage).
- Le mode Patron/PIN et les routes protégées ne changent pas de mécanisme.
- Le module A reste intact : le module B réutilise `product_units` sans le
  modifier.

## 4. Migrations Supabase à prévoir (ordre indicatif, détaillé dans le plan)

1. `shop_settings` + RLS (lecture/écriture réservée aux membres de la boutique).
2. `product_units`, `supply_cycles`, `cycle_losses` + colonnes `sale_items.cycle_id`,
   `sale_items.unit_id`, `sale_items.quantity_in_base` + RLS.
3. `shop_takings`, `inventory_counts`, `stock_transfers` + types de mouvements
   étendus + RLS, puis relâchement de l'hypothèse « un seul shop par membre »
   côté client Flutter (`sync_service.dart`).
