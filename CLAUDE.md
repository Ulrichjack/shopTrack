# CLAUDE.md — Instructions pour Claude Code

> Référence principale, volontairement concise. Le détail vit dans `RECAPITULATIF_TECHNIQUE.md` (état technique), `PLAN_CORRECTIONS_ET_AMELIORATIONS.md` (audit/backlog), `docs/` (architecture des modules métier) et les skills `.claude/skills/`.
>
> **GOUVERNANCE** : budget 120 lignes max (hook automatique). Avant TOUT ajout ici, suivre `.claude/skills/context-governance/SKILL.md`.

## Projet

**ShopTrack** — app Flutter de gestion de boutique (vente, stock, caisse) pour petits commerces au Cameroun (FCFA). Local-first : chaque opération est écrite en local puis synchronisée. Documentation et code métier en **français**.

| Clé | Valeur |
|-----|--------|
| Branche de travail | `develop` (branches `feature/*` par domaine, `main` = release) |
| Package Android | `cm.shoptrack.shoptrack` |
| Backend | Supabase (Auth, Postgres, RLS, Storage) |

**Stack** : Flutter, Riverpod (état), GoRouter (nav), Drift/SQLite (cache local), Supabase (distant), `mobile_scanner`/`qr_flutter` (codes-barres/QR), `pdf`/`printing` (bilans).

## Architecture

```
lib/
├── core/            # database (Drift), sync/ (file d'attente + SyncService), providers/app_mode_provider (PIN Patron), audit, backup
├── features/<nom>/  # data/ (datasources, repositories, models) · domain/ (entities, repositories) · presentation/ (providers, screens)
└── router.dart       # GoRouter ; redirect() bloque les routes Patron (bossOnlyRoutes) si bossModeAccess == false
```

Synchro (`lib/core/sync/sync_service.dart`) : `processQueue()` (push) puis `pullDataFromSupabase()` **seulement si** la file locale est vide — sinon un stock local non envoyé est écrasé. La garde vit **dans** `pullDataFromSupabase()` : ne jamais la remonter chez l'appelant, des écrans appellent le pull directement. Mouvements de stock : RPC atomique `apply_stock_movement` (idempotent via `stock_sync_operations.id`).

Cette garde vaut pour **tout** téléchargement, pas seulement `pullDataFromSupabase()` : `shop_settings_provider` la contournait et faisait revenir un module désactivé, le serveur renvoyant l'ancien réglage encore en file.

**Toute table/colonne synchronisée se déclare dans `tablesTirees` (`lib/core/sync/pull_registry.dart`)**, requête distante et mapping Drift au même endroit. Oubli = le pull réécrit la ligne locale sans le champ et l'efface silencieusement quelques secondes après sa création — vu sur `sale_items.cycle_id`, invisible sur un seul téléphone. `test/sync_pull_coverage_test.dart` nomme la colonne fautive.

Une opération refusée par le serveur ne gèle plus la file : après 5 refus elle est **mise de côté** (gardée, signalée par un bandeau) et seules les opérations de même portée l'attendent. Une panne réseau n'est pas un refus (`estUnRefusDuServeur`).

## Règles CRITIQUES

**Secrets Android** : `android/shoptrack-release.jks`, `release-signing.pass`, `key.properties` sont gitignorés et **ne doivent jamais être commités**. Leur perte empêche toute mise à jour signée compatible. Sauvegarde hors PC obligatoire, hors de ce dépôt.

**`lib/supabase_config.dart`** : présent dans `.gitignore` mais **reste suivi par Git** (fichier déjà indexé avant l'ajout au gitignore — `git rm --cached` n'a jamais été fait). Il ne contient que l'URL et la clé anonyme publique (sécurité déléguée à RLS, pas à la confidentialité de cette clé) — ne jamais y ajouter une clé `service_role` ou un secret serveur.

**PIN Patron** : jamais en clair. Utiliser le hachage salé existant (`lib/core/providers/app_mode_provider.dart`), ne pas le contourner.

**Protection des routes Patron** : `bossOnlyRoutes` dans `router.dart` est la seule barrière ; toute nouvelle route sensible doit y être ajoutée, pas seulement cachée dans l'UI.

**Migrations Supabase** : fichiers dans `supabase/migrations/`, appliquées **dans l'ordre du nom de fichier** (`supabase db push`). Toute nouvelle migration doit être ajoutée à la liste du `README.md`.

## Commandes

```bash
flutter pub get
flutter test
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter run
flutter build apk --release
supabase db push          # applique les migrations, dans l'ordre
```

## État du projet

Bêta contrôlée, pas encore production (tests multi-téléphones réels et scénarios hors-ligne non finalisés). Détail : `RECAPITULATIF_TECHNIQUE.md` (état au 28/07/2026) et `PLAN_CORRECTIONS_ET_AMELIORATIONS.md` (audit + backlog priorisé).

## Workflows → Skills

| Tâche | Ressource |
|-------|-----------|
| Avant une livraison, ou en revue de synchro / mapping / écran de saisie | `docs/PIEGES_CONNUS.md` — bugs déjà rencontrés et ce qui les a trahis |
| Modifier CLAUDE.md / AGENTS.md / skills / docs projet | `.claude/skills/context-governance/SKILL.md` |
| Architecture des modules métier custom (cycles œufs, multi-point/inventaire) | `docs/ARCHITECTURE_MODULES.md` · avancement `docs/PLAN_MODULES_CLIENTS.md` · tests `docs/PLAN_TESTS_MODULES.md` |
| Stock d'un produit | En mode cycles ou inventaire, le stock est géré par le module (arrivage, comptage) : les écrans produit **masquent** la quantité et ne la réécrivent jamais |
| Retirer un produit | **Archiver** (`archivedAt`) dès qu'il a une vente/comptage/transfert — supprimer réécrirait un bilan déjà consulté. La suppression ne vaut que pour un produit qui n'a jamais servi |
| Ajouter un champ propre à un module | Le poser sur la table partagée en **nullable**, et n'afficher le champ que dans le mode concerné (`shopSettingsProvider`). Dupliquer un écran ne se justifie que si son **contenu** diffère (l'accueil), pas pour un champ de plus |
| Écrire un écran | Valider sur **petit écran** (Pixel 4a) : 3 bugs de contenu masqué en bas déjà rencontrés. Toute liste sous un bouton flottant réserve ~96px en bas ; tout formulaire est scrollable (le clavier réduit la hauteur). Direction visuelle cible : `PLAN_CORRECTIONS_ET_AMELIORATIONS.md` §12 (long terme) |
