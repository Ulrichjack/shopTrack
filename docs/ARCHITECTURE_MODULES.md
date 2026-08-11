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

### Ce qui existe déjà et qu'on réutilise

Le schéma Supabase est **déjà multi-boutique** au niveau RLS (`is_shop_member`
vérifie l'appartenance par ligne, pas une seule boutique globale). La seule limite
actuelle est côté client : `sync_service.dart` suppose un seul `shop_id` par
utilisateur (`shop_members...single()`). Il faudra relâcher cette hypothèse (un
patron peut appartenir à plusieurs `shop_members`) plutôt que changer le schéma.

### Nouvelles entités

- **`stock_transfers`** : `id, from_shop_id, to_shop_id, product_id, quantity,
  transferred_at, status (pending/received), created_by`. Distinct d'une vente —
  répond au besoin §6 du client (traçabilité propre transferts vs ventes clients).
- **`monthly_inventories`** : `id, shop_id, product_id, period_start, period_end,
  opening_stock, stock_in (achats + transferts entrants), transfers_out, losses,
  closing_stock_counted, estimated_sold (calculée), closed_at`.
- **Mouvements de stock typés** (extension de `stock_movements.type`) :
  `purchase | transfer_in | transfer_out | loss | inventory_adjustment` — permet de
  isoler "ventes estimées" du reste plutôt que de tout mélanger dans une seule
  soustraction (le client a explicitement demandé de gérer transferts/pertes/retours
  séparément, §10 de son besoin).

### Calcul (fonction pure `lib/core/utils/inventory_reconciliation_calculator.dart`)

```
ventes_estimées = opening_stock + stock_in − transfers_out − losses − closing_stock_counted
```

### Écran/dossier

`lib/features/inventory/` : sélection du point de vente actif (si patron multi-
boutique), saisie de transfert, clôture d'inventaire mensuelle, rapport consolidé
tous points.

### Point d'architecture à trancher avec le client / toi

Ce module change le **mode de saisie par défaut** (pas de vente unitaire enregistrée).
Ça doit rester un mode alterné par boutique (`sale_capture_mode`), jamais mélangé avec
le mode temps réel dans la même boutique — sinon `ventes_estimées` compterait aussi les
ventes déjà enregistrées et fausserait le calcul.

## 3. Ce qui NE change PAS

- Le modèle `Product`/`Sale` simple actuel reste le chemin par défaut
  (`unit_mode: simple`, `sale_capture_mode: realtime`) pour toute boutique qui n'a
  besoin d'aucun des deux modules — aucune régression pour les testeurs bêta actuels.
- Le moteur de sync (`processQueue` → `pullDataFromSupabase` si file vide) est réutilisé
  tel quel ; les nouvelles tables suivent le même pattern (file locale → RPC/upsert →
  merge, jamais de suppression locale avant remplissage).
- Le mode Patron/PIN et les routes protégées ne changent pas de mécanisme.

## 4. Migrations Supabase à prévoir (ordre indicatif, détaillé dans le plan)

1. `shop_settings` + RLS (lecture/écriture réservée aux membres de la boutique).
2. `product_units`, `supply_cycles`, `cycle_losses` + colonnes `sale_items.cycle_id`,
   `sale_items.unit_id`, `sale_items.quantity_in_base` + RLS.
3. `stock_transfers`, `monthly_inventories` + RLS + relâchement de l'hypothèse
   "un seul shop par membre" côté client Flutter.
