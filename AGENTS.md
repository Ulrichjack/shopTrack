# AGENTS.md — Point d'entrée pour Codex et agents compatibles

> `CLAUDE.md` est la référence la plus complète ; ce fichier en extrait les règles
> opérationnelles.

## Lecture au démarrage

1. Lire ce fichier.
2. Lire `CLAUDE.md` (stack, architecture, règles critiques, commandes).
3. Pour l'état technique détaillé : `RECAPITULATIF_TECHNIQUE.md`.
4. Pour le backlog/audit : `PLAN_CORRECTIONS_ET_AMELIORATIONS.md`.
5. Avant de modifier `CLAUDE.md`, `AGENTS.md`, un skill ou la doc racine :
   lire `.claude/skills/context-governance/SKILL.md` (budget CLAUDE.md : 120 lignes,
   appliqué par hook).

## Projet

- ShopTrack — app Flutter de gestion de boutique (vente, stock, caisse), local-first,
  synchronisée avec Supabase. Cible : petits commerces au Cameroun (FCFA).
- Documentation et code métier en **français**.
- Stack : Flutter, Riverpod, GoRouter, Drift/SQLite (local), Supabase (distant),
  `mobile_scanner`/`qr_flutter`, `pdf`/`printing`.
- Branche de travail `develop`, branches `feature/*` par domaine.

## Règles critiques

- Ne jamais committer `android/shoptrack-release.jks`, `release-signing.pass`,
  `android/key.properties` (gitignorés, perte = plus aucune mise à jour signée possible).
- `lib/supabase_config.dart` reste suivi par Git malgré le `.gitignore` (legacy) —
  ne contient que la clé anonyme publique Supabase ; ne jamais y mettre un secret serveur.
- PIN Patron : toujours haché/salé via `lib/core/providers/app_mode_provider.dart`,
  jamais en clair.
- Routes Patron protégées uniquement via `bossOnlyRoutes` dans `router.dart` — toute
  nouvelle route sensible doit y être ajoutée.
- Synchro : `processQueue()` (push) doit toujours précéder `pullDataFromSupabase()`,
  et le pull ne doit avoir lieu que si la file locale est vide (garde placée
  *dans* `pullDataFromSupabase()`, car des écrans l'appellent directement).
- Toute nouvelle colonne/table synchronisée doit être ajoutée aux deux côtés de
  `pullDataFromSupabase()` (`select` distant + mapping Drift), sinon le pull
  efface le champ silencieusement juste après son enregistrement.
- Migrations Supabase appliquées dans l'ordre du nom de fichier
  (`supabase/migrations/`), et listées dans `README.md`.

## Commandes utiles

```bash
flutter pub get
flutter test
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter run
flutter build apk --release
supabase db push
```

## Vérification avant livraison

- `flutter analyze` et `flutter test` doivent passer (ou toute régression doit être
  justifiée explicitement).
- Changement touchant la synchro ou le stock : vérifier le comportement hors-ligne/en
  ligne, pas seulement le cas nominal connecté.
