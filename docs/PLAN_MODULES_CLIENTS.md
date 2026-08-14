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

**Module A validé sur téléphone réel le 2026-08-12** (30 scénarios, dont le
multi-appareils et le hors ligne — voir `docs/PLAN_TESTS_MODULES.md`). Le
module B peut donc démarrer.

### Étape 2 — Module B (inventaire périodique multi-boutique)

Conception figée le 2026-08-13 après échange direct avec le client :
`docs/ARCHITECTURE_MODULES.md` §2. **Règle absolue : aucun écran du mode
simple ni du module A n'est modifié.** Le module B vit dans
`lib/features/inventory/` et se contente de réutiliser les données
(produits, stock, boutiques, synchro).

Ordre d'implémentation, du plus indépendant au plus risqué :

- [x] **B1 — Recette journalière.** Table `shop_takings` (shop_id, date,
  amount, une seule par jour et par boutique), écran de saisie minimal,
  synchro. Aucune dépendance : c'est la seule saisie quotidienne demandée au
  commerçant, et rien ne se croise sans elle.
- [x] **B2 — Calculateur pur** `inventory_reconciliation_calculator.dart` +
  tests, sur le modèle de `cycle_result_calculator.dart` : sorties totales →
  pertes déclarées → ventes présumées → écart avec l'argent encaissé.
  Fait, avec le garde-fou des ventes négatives (un produit mal compté ne peut
  plus empoisonner le total de la boutique) et la marge par produit.
- [x] **B3 — Comptage d'inventaire.** Table `inventory_counts` (repères par
  produit), écran de saisie **à l'aveugle** (ne jamais afficher la quantité
  théorique), sauvegarde progressive, indicateur « 22 produits sur 30 ».
- [x] **B4 — Approvisionnement avec prix.** Table `stock_purchases` (déjà en
  base), champ « Prix d'achat unitaire » dans la recharge, affiché uniquement
  en mode périodique et pré-rempli au dernier prix connu. Le rapport valorise
  par **moyenne pondérée mobile** (`weightedUnitCost`) : stock d'ouverture au
  coût des achats antérieurs + achats de la période à leur prix réel. Pas du
  FIFO — on ne sait pas quel exemplaire est parti — mais stable : une période
  close ne bouge plus. Sans ligne d'achat, on retombe exactement sur l'ancien
  comportement (prix du produit).
- [x] **B5 — Pertes du module B.** Table `inventory_losses` (déjà en base),
  écran « Déclarer une perte » (produit, quantité, raison parmi casse ·
  périmé · invendu · vol · autre, date, note), synchro dans les deux sens,
  branchée dans le rapport sur la fenêtre de la période. **Ne touche pas au
  stock** : en périodique le stock ne bouge qu'au comptage, la marchandise
  cassée a déjà quitté l'étagère.
- [~] **B6 — Rapport par boutique.** Écran fait et vérifié sur 15 produits :
  sorties, valeur, gain par produit, écart nommé, bénéfice parti des recettes
  réelles. **Restent** le PDF (réutiliser celui du bilan existant) et le
  stockage du bilan une fois clôturé, pas recalculé — sinon il change sous les
  yeux du patron quand une donnée arrive en retard.
- [ ] **B7 — Multi-boutique.** Sélecteur de boutique + relâchement de
  l'hypothèse un-seul-shop-par-membre dans `sync_service.dart`
  (`shop_members...single()`). **La partie la plus risquée** : elle touche le
  cœur de la synchro, donc en dernier, une fois le calcul prouvé sur une
  seule boutique.
- [ ] **B8 — Transferts entre boutiques.** N'a de sens qu'après B7. Stock
  déplacé immédiatement des deux côtés, vérification à l'arrivée (le client a
  confirmé qu'ils vérifient), écart enregistré comme perte de transport.

**Décisions verrouillées** (détail dans l'architecture) : période libre,
comptage complet, unité = simple étiquette texte par produit (pas de
conversion, pas de `product_units`), quantités **entières**, dernier prix
d'achat, recette par boutique, pas de vente à crédit.

**Emprunts à FishCam** (`/home/jack/CODE/FishCam_backend`, même auteur, ERP
poissonneries au Cameroun déjà en production) : le concept
`totalVentePrevisibleMois` vs `totalVenteRealisee` y est déjà validé sur le
terrain — c'est exactement notre croisement attendu/encaissé. À reprendre
aussi : le prix sur la ligne d'achat (`LigneAchat.prixUnitaireCarton`), le
rappel quotidien (`TypeNotification.RAPPORT_JOURNALIER`),
`nombreJoursTravailles` pour ne pas compter un jour fermé comme une recette
manquante, et le bilan figé après clôture. On reprend les **décisions
métier**, pas le code (Java/Spring serveur contre Flutter local-first).

**Limites assumées, à revoir si le terrain les remonte** : pas de décimales
(le gramme et le litre supposeraient de passer tout le stock en décimal, ce
qui casserait le module A) ; si le prix de vente change en cours de période,
la valeur attendue est pondérée par les jours et reste approximative.

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
