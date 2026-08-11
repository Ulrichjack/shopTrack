# Plan d'implémentation — Modules clients (2026-08-09)

> Suite de `docs/ARCHITECTURE_MODULES.md` (architecture validée). Ce document est le
> suivi vivant de l'implémentation, étape par étape, entre sessions. On coche au fur
> et à mesure ; on n'y recopie pas l'architecture (→ voir le doc source).

## Ordre retenu

Progression volontairement petite et pédagogique (apprentissage en pairing), pas de
gros commit d'un coup.

### Étape 0 — Fondation `shop_settings` (faite côté code, migration à appliquer)

- [x] Migration Supabase `shop_settings` (+ RLS lecture/écriture membres boutique) —
  `supabase/migrations/202608090001_shop_settings.sql`, **pas encore appliquée** sur
  le projet Supabase (à faire via SQL Editor ou `supabase db push`)
- [x] Table Drift locale `LocalShopSettings` (cache) — `schemaVersion` 1 → 2 avec
  migration `onUpgrade`, pour ne rien casser sur les téléphones déjà installés
- [x] `shopSettingsProvider` (Riverpod) — `lib/core/providers/shop_settings_provider.dart`
- [x] Point d'usage de vérification — section "MODULE DE VENTE" (lecture seule),
  visible uniquement en mode Patron, dans `profile_screen.dart`

**Décision prise (2026-08-09) sur le choix du mode par boutique** : pas d'écran de
choix à l'inscription. Toute nouvelle boutique démarre en mode simple par défaut
(zéro friction — ces modules ne concernent que 2 clients identifiés, pas un choix
générique à proposer à tout le monde). Le mode sera modifiable plus tard dans un
écran Paramètres réservé au Patron (`bossModeAccess`), à construire au moment où on
implémente réellement l'activation du Module A/B (pas fait maintenant — l'affichage
actuel est en lecture seule).

### Étape 1 — Module A (client œufs)

- [x] Migration Supabase `product_units`, `supply_cycles`, `cycle_losses` +
  colonnes `sale_items.cycle_id/unit_id/quantity_in_base/unit_sell_price` —
  `supabase/migrations/202608090002_module_a_cycles.sql`, **pas encore
  appliquée**
- [x] Tables Drift locales + extension `LocalSaleItems` (`schemaVersion` 2→3)
- [x] `lib/core/utils/cycle_result_calculator.dart` (pur, testé —
  `test/cycle_result_calculator_test.dart`)
- [x] Écran création de cycle (`create_cycle_screen.dart`, route
  `/create-cycle`, accessible depuis Profil → MODULE DE VENTE si
  `unit_mode = hierarchical`) — `case 'ADD_SUPPLY_CYCLE'` ajouté dans
  `sync_service.dart`
- [x] Gestion des unités par produit (`manage_units_screen.dart`, route
  `/manage-units`) — nécessaire avant toute vente par unité
- [x] Écran saisie de perte (`loss_entry_screen.dart`, route `/loss-entry`)
- [x] Vente par unité (`cycle_sale_screen.dart`, route `/cycle-sale`) —
  sélecteur d'unité + conversion vers l'unité de base, écrit
  `sale_items.cycle_id/unit_id/quantity_in_base/unit_sell_price` en
  réutilisant `saleProvider.createSale` (donc le stock, le dashboard et la
  synchro existants restent la seule source de vérité)
- [x] Écran rapport de cycle (`cycle_report_screen.dart`, route
  `/cycle-report`) — utilise `cycle_result_calculator.dart`

Correction importante faite en cours de route : `createCycle()` incrémente
maintenant aussi `products.quantity` (même mécanisme qu'une recharge de stock
classique) — sans ça, la quantité reçue dans un cycle n'était jamais
vendable. Une perte (`cycle_losses`) décrémente le stock de la même façon
(delta négatif, `apply_stock_movement`, type `'loss'`).

**Intégration dans l'app (décidé le 2026-08-09)** : le mode ne doit pas être
un sous-menu du Profil mais changer la structure même de l'app. Concrètement :
- onglet **Cycles** dans la barre de navigation (`cycles_hub_screen.dart`,
  route `/cycles`), visible seulement si `unit_mode = 'hierarchical'` — il
  regroupe cycles, pertes, rapport et unités ;
- le bouton **NOUVELLE VENTE** du Dashboard ouvre `/cycle-sale` en mode œufs,
  `/sales/new` sinon (même bouton, même place, écran adapté) ;
- la section « MODULE DE VENTE » du Profil a été **supprimée** ;
- `main_layout.dart` construit désormais ses onglets depuis une seule liste
  (`_NavDestination`), donc l'index tapé et l'index surligné ne peuvent plus
  se désynchroniser quand un onglet apparaît/disparaît selon le mode ;
- Stock / Ventes / Bilan restent **communs aux deux modes** (créer un produit,
  historique, clôture de caisse servent au vendeur d'œufs comme aux autres).

**Bug d'indépendance corrigé** : une vente en mode simple envoyait quand même
les colonnes Module A (`cycle_id`...) à Supabase — donc elle aurait été
rejetée sur toute base où `202608090002` n'est pas appliquée. Ces clés ne sont
maintenant ajoutées au payload que pour une vente de cycle.

Le calcul de conversion (unité vendue → unité de base) a été sorti de l'écran
vers `UnitSaleConversion` dans `cycle_result_calculator.dart` : c'est lui qui
détermine le chiffre d'affaires, il doit être pur et testé.

**Leçon du premier test réel (2026-08-10)** : l'utilisateur a créé une unité
nommée « 30 » avec un ratio de 360, puis vendu « 1 » — soit un carton entier
de 360 œufs pour 2 000 F, d'où un bénéfice de −16 000 F. Le calcul était
juste, la saisie ne l'était pas, et **rien à l'écran ne montrait la
conversion**. Corrections apportées :
- récapitulatif temps réel dans `cycle_sale_screen.dart` (quantité en unités
  de base, stock disponible, total encaissé, coût réel, bénéfice **ou perte
  en rouge**, alerte stock insuffisant avant validation) ;
- phrase de relecture dans `manage_units_screen.dart` (« 1 plateau = 30
  unité(s) de base ») + champ nom qui précise « un mot, pas un nombre » ;
- suppression d'une unité possible, **refusée si elle a déjà servi à une
  vente** (sinon les lignes de vente pointeraient dans le vide).

À retenir pour la suite : sur toute saisie qui subit une conversion, afficher
le résultat converti avant validation — c'est le seul garde-fou réaliste.

**Trois bugs de synchronisation trouvés au test réel (2026-08-10)**, tous
invisibles en tests unitaires et sur un seul téléphone :

1. **Stock qui « remonte » après une vente.** La garde « pull seulement si la
   file est vide » existait dans `synchronize()`, mais `dashboard_provider` et
   `monthly_report_screen` appelaient `pullDataFromSupabase()` directement et
   la contournaient : le serveur, qui ignorait encore la vente, réécrivait
   l'ancien stock. La garde a été déplacée **dans** `pullDataFromSupabase()`.
   Ce bug touchait aussi le mode simple. Verrouillé par
   `test/sync_pull_guard_test.dart`.
2. **Lien vente ↔ cycle effacé.** Le mapping du pull ne recopiait pas
   `cycle_id`, `unit_id`, `quantity_in_base`, `unit_sell_price` : la vente
   partait correctement puis revenait amputée, et le rapport affichait 0 F.
3. **Cycles/unités/pertes jamais téléchargés.** Le pull ne les demandait pas :
   un 2e téléphone n'aurait vu aucun cycle ni aucune unité, donc n'aurait pas
   pu vendre au plateau.

Règle générale tirée de tout ça, reportée dans `CLAUDE.md` et `AGENTS.md` :
une nouvelle colonne synchronisée doit être ajoutée **aux deux côtés** du
pull, sinon elle est silencieusement effacée après coup.

**Pas encore fait** : fermeture d'un cycle (`status: 'closed'`) ; migration
`202608090002_module_a_cycles.sql` toujours pas appliquée sur Supabase ;
affichage du stock en unités de base plutôt qu'en plateaux/cartons — **laissé
volontairement en l'état, à trancher après le retour du client** (la donnée
est correcte, seul l'affichage est en question).

Détail des entités : `docs/ARCHITECTURE_MODULES.md` §1.

**En pause volontairement (2026-08-09)** : on ne démarre pas le Module B tant
que le Module A n'est pas testé et validé par l'utilisateur sur son
téléphone. Ne pas reprendre l'étape 2 sans confirmation explicite.

### Étape 2 — Module B (multi-point/inventaire) — EN ATTENTE

`stock_transfers`, `monthly_inventories`, extension `stock_movements.type`,
`inventory_reconciliation_calculator.dart`, écrans `lib/features/inventory/`, et
relâchement de l'hypothèse un-seul-shop-par-membre dans `sync_service.dart`. Détail :
`docs/ARCHITECTURE_MODULES.md` §2.

## Idées ouvertes issues des discussions (non tranchées)

- **Abonnement payant par boutique.** Piste : réutiliser le même mécanisme de garde
  que `bossModeAccess`/`shop_settings` (un statut par boutique, vérifié au routeur),
  plutôt qu'un système séparé. Idée à creuser : lier le *tier* d'abonnement aux
  modules débloqués (base = simple, tiers supérieurs = module A et/ou B activables) —
  ça donne un modèle de monétisation direct plutôt que deux systèmes parallèles.
  Recommandation initiale : ne pas intégrer de paiement en ligne tout de suite (app
  encore en bêta) — commencer par un statut activé/désactivé manuellement, migrer
  vers Mobile Money (MTN/Orange, pertinent au Cameroun plutôt que Stripe) une fois le
  reste stabilisé. Non commencé.
- **Inventaire physique / écarts de stock hors Module B.** Déjà identifié dans
  `PLAN_CORRECTIONS_ET_AMELIORATIONS.md` §12 (moyen terme) mais jamais implémenté.
  Constat en relisant le code (`LocalStockMovements` dans
  `lib/core/database/app_database.dart`) : aujourd'hui un mouvement de stock n'a
  qu'une quantité et un type, pas de motif (casse/perte/ajustement) ni de rapprochement
  comptage physique vs stock système — cette faiblesse existe même en mode simple, pas
  seulement pour le client multi-point. Piste : généraliser le mécanisme
  `monthly_inventories` du Module B (§2 de l'architecture) pour qu'il soit utilisable
  par n'importe quelle boutique en mode `realtime`, pas uniquement en mode
  `periodic` — à trancher avant l'étape 2. Non commencé.

## Tests

Scénarios exhaustifs et leur état : `docs/PLAN_TESTS_MODULES.md`.

## Outillage de suivi

- Suivi fin (sous-étapes d'une session) : tâches `TaskCreate`/`TaskUpdate` de la
  session en cours.
- Suivi entre sessions : ce fichier (coché au fur et à mesure) + mémoire projet
  (décisions/contexte non dérivable du repo).
