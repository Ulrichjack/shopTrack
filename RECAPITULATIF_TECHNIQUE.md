# ShopTrack — Récapitulatif technique des modifications

Date : 28 juillet 2026
Version Android : `1.0.0+2`
Branche : `develop`
Package Android : `cm.shoptrack.shoptrack`

## 1. État du livrable

La version actuelle est adaptée à une bêta contrôlée et aux tests réels avec
quelques utilisateurs.

Artefact disponible :

```text
build/app/outputs/flutter-apk/app-release.apk
```

Caractéristiques de la release :

- APK release signé ;
- signature APK v2 valide ;
- certificat RSA 4096 bits ;
- alias de signature : `shoptrack` ;
- certificat :
  `CN=ShopTrack, OU=Mobile, O=ShopTrack, L=Douala, ST=Littoral, C=CM` ;
- empreinte SHA-256 :
  `91:08:CD:AD:63:12:3E:D1:50:8C:EF:9D:4D:AF:88:2F:D9:B9:95:D4:A0:82:AD:5F:9F:F9:B8:92:4B:25:AB:86`.

Cette version n'est pas encore déclarée comme production commerciale finale :
elle doit d'abord être validée sur plusieurs téléphones et avec plusieurs
comptes/boutiques.

## 2. Architecture actuelle

ShopTrack utilise :

- Flutter pour Android/iOS ;
- Riverpod pour l'état applicatif ;
- GoRouter pour la navigation ;
- Drift/SQLite pour la base locale ;
- Supabase Auth, PostgreSQL, Storage et PostgREST pour le distant ;
- une file locale `sync_queue_items` pour le mode hors connexion ;
- `mobile_scanner` pour les QR/codes-barres ;
- `qr_flutter` pour la génération des QR ;
- `pdf` et `printing` pour les bilans PDF.

Le principe est **local-first** :

1. l'opération métier est écrite localement ;
2. elle est placée dans la file de synchronisation ;
3. l'interface continue de fonctionner hors ligne ;
4. quand Internet revient, la file est envoyée dans l'ordre ;
5. les données Supabase sont ensuite fusionnées dans le cache local.

## 3. Scanner QR et codes-barres

Fichier principal :

```text
lib/features/products/presentation/screens/barcode_scanner_screen.dart
```

Modifications :

- remplacement de l'erreur générique avec point d'exclamation ;
- messages spécifiques pour permission refusée, caméra indisponible,
  contrôleur non initialisé et appareil non compatible ;
- bouton **Réessayer** ;
- saisie manuelle du code ;
- changement de caméra ;
- gestion du flash ;
- arrêt après la première détection ;
- retour haptique après détection ;
- gestion du cycle de vie Flutter ;
- démarrage manuel unique pour éviter une double initialisation native ;
- sérialisation des commandes caméra sur les appareils Android sensibles ;
- arrêt à la mise en arrière-plan ;
- redémarrage au retour dans l'application ;
- libération correcte du contrôleur ;
- limitation aux formats réellement utiles ;
- ajout de `NSCameraUsageDescription` sur iOS.

## 4. Recherche produit multi-téléphone

Fichier principal :

```text
lib/features/products/presentation/providers/product_provider.dart
```

Après un scan :

1. normalisation du code ;
2. recherche dans Drift ;
3. tentative d'envoi des opérations locales ;
4. recherche dans Supabase si le produit est absent localement ;
5. mise en cache du produit distant ;
6. rafraîchissement de `productProvider`.

Cela permet à un téléphone B de retrouver un produit créé sur le téléphone A,
à condition que le produit A ait été synchronisé.

## 5. Unicité des QR

L'ancienne version acceptait plusieurs produits avec le même QR. Le cas réel
constaté était :

```text
ampoule
ampoule 2
QR-1784980274459
```

Corrections :

- contrôle du code dans Drift avant création/modification ;
- contrôle dans Supabase lorsque le téléphone est en ligne ;
- message indiquant le produit qui possède déjà le code ;
- QR automatiques basés sur microsecondes + UUID ;
- index PostgreSQL unique `(shop_id, barcode)` ;
- migration automatique des doublons historiques sans supprimer de produit.

Hors ligne :

- le même téléphone refuse immédiatement un code déjà présent localement ;
- deux téléphones simultanément hors ligne ne peuvent pas connaître leurs
  créations mutuelles ;
- dans ce dernier cas, la contrainte Supabase refuse le doublon au moment de la
  synchronisation.

## 6. Synchronisation

Fichier principal :

```text
lib/core/sync/sync_service.dart
```

Améliorations :

- écran d'état de synchronisation ;
- nombre d'opérations en attente ;
- dernière date de réussite ;
- conservation de la dernière erreur ;
- traitement strictement ordonné de la file ;
- arrêt au premier échec pour respecter les dépendances ;
- `upsert` pour les opérations rejouables ;
- fusion du distant au lieu de supprimer les tables locales ;
- aucun téléchargement distant si une écriture locale reste en attente ;
- prévention de l'écrasement d'un stock local non synchronisé ;
- méthode explicite `synchronize()` : push, puis pull seulement si le push est
  complet.

Problème réel diagnostiqué :

- une vente et son article avaient atteint Supabase ;
- le mouvement de stock avait échoué ;
- la clôture attendait derrière la vente ;
- le téléchargement distant pouvait restaurer un ancien stock.

La correction empêche désormais ce téléchargement tant que la file n'est pas
vide.

## 7. Ventes et stock

Fichiers principaux :

```text
lib/features/sales/presentation/providers/sale_provider.dart
lib/core/sync/sync_service.dart
```

Corrections :

- vente, articles, stock local et entrée de file enregistrés dans une
  transaction Drift ;
- vérification du stock au moment de confirmer ;
- refus d'une quantité négative ou supérieure au stock ;
- identifiants stables pour les ventes, articles et mouvements ;
- `upsert` des ventes et articles ;
- opération distante de stock atomique ;
- mouvement traité une seule fois grâce à
  `stock_sync_operations.id` ;
- nouvelle tentative sans double décrément ;
- refus du stock distant négatif ;
- distinction entre historique de recharge et articles vendus.

Migration associée :

```text
supabase/migrations/202607280002_stock_sync_and_unique_barcodes.sql
```

## 8. Nouvelle vente

Fichier :

```text
lib/features/sales/presentation/screens/new_sale_screen.dart
```

Modifications :

- affichage de la photo du produit à la place de sa première lettre ;
- prise en charge des images Supabase ;
- prise en charge des images locales hors ligne ;
- indicateur de chargement ;
- icône de secours en cas d'image absente ou invalide ;
- recherche du produit scanné dans Drift puis Supabase ;
- messages de recherche plus explicites.

## 9. Clôture et bilan

Fichiers principaux :

```text
lib/features/dashboard/presentation/providers/dashboard_provider.dart
lib/features/dashboard/presentation/screens/closing_screen.dart
lib/features/reports/presentation/providers/monthly_report_provider.dart
lib/features/reports/presentation/screens/monthly_report_screen.dart
```

Corrections :

- même calcul utilisé dans le dashboard et dans la clôture ;
- seul le dernier solde du matin est retenu ;
- ventes et retraits calculés sur la journée concernée ;
- clôture locale remplacée au lieu d'être dupliquée ;
- date de clôture normalisée ;
- saisie physique validée ;
- virgule décimale acceptée ;
- note de clôture facultative ;
- écran rendu défilable avec le clavier ouvert ;
- correction du `BOTTOM OVERFLOWED` ;
- affichage séparé des manques ;
- affichage séparé des surplus ;
- total signé des écarts ;
- résultat ajusté = bénéfice net + écarts de caisse ;
- ajout de l'écart dans le tableau journalier ;
- ajout des écarts dans le PDF.

Le calcul pur a été extrait dans :

```text
lib/core/utils/daily_cash_calculator.dart
```

## 10. Mode Patron et sécurité locale

Fichier principal :

```text
lib/core/providers/app_mode_provider.dart
```

Modifications :

- PIN non stocké en clair ;
- sel aléatoire ;
- hachage SHA-256 itéré ;
- comparaison en temps constant ;
- migration transparente de l'ancien PIN ;
- limitation temporaire après plusieurs échecs ;
- protection des routes Bilan et Audit ;
- suppression du rafraîchissement GoRouter responsable de l'assertion
  `_dependents.isEmpty` ;
- le mode Patron reste actif après redémarrage ;
- le mode Vendeur persiste uniquement après verrouillage manuel.

La déconnexion :

- tente d'envoyer la file ;
- est refusée si des opérations restent en attente ;
- crée une sauvegarde avant d'effacer les données locales.

## 11. Audit et sauvegardes

Nouveaux fichiers :

```text
lib/core/audit/activity_log_screen.dart
lib/core/backup/backup_service.dart
lib/core/sync/sync_status_screen.dart
```

Fonctionnalités :

- historique local des ventes ;
- mouvements de caisse ;
- recharges de stock ;
- clôtures et écarts ;
- identification courte de l'utilisateur ;
- export JSON manuel depuis le profil Patron ;
- export automatique après clôture ;
- sauvegarde des produits, ventes, articles, mouvements, clôtures et file de
  synchronisation ;
- stockage dans `Documents/ShopTrackBackups`.

## 12. Migrations Supabase

Les migrations sont versionnées dans :

```text
supabase/migrations/
```

### `202607270001_secure_sync.sql`

- fonction d'appartenance à une boutique ;
- RLS produits, ventes, articles, caisse, stock et clôtures ;
- fonction initiale de stock atomique ;
- unicité d'une clôture par boutique/date.

### `202607280002_stock_sync_and_unique_barcodes.sql`

- table technique `stock_sync_operations` ;
- nouvelle fonction atomique/idempotente de stock ;
- compatibilité avec l'ancien `stock_movements` limité aux recharges ;
- réparation des QR déjà dupliqués ;
- index unique QR par boutique.

État vérifié le 28 juillet 2026 :

- migration 002 active ;
- file locale du téléphone : `0` opération ;
- QR dupliqués dans Supabase : `0`.

## 13. Signature Android

Fichiers secrets locaux :

```text
android/shoptrack-release.jks
android/release-signing.pass
android/key.properties
```

Ils sont ignorés par Git.

Ces trois fichiers doivent être sauvegardés hors du PC, ensemble, dans un
emplacement privé et chiffré. La perte de la clé empêche de publier une mise à
jour signée compatible avec l'application existante.

Fichier versionné sans secret :

```text
android/key.properties.example
```

Le build Gradle :

- lit le mot de passe depuis un fichier secret ;
- n'utilise plus la clé debug pour `release` ;
- signe l'APK avec l'alias `shoptrack`.

## 14. Tests et validations

Tests présents :

```text
test/daily_cash_calculator_test.dart
test/app_mode_provider_test.dart
```

Cas testés :

- dernier solde du matin ;
- séparation chiffre d'affaires/bénéfice ;
- journée vide ;
- persistance du mode Patron ;
- persistance du verrouillage manuel.

Résultat :

```text
5 tests réussis
```

Validations effectuées :

- analyse Flutter des fichiers critiques sans erreur ;
- APK debug compilé ;
- APK release compilé ;
- signature release vérifiée avec `apksigner` ;
- synchronisation Supabase contrôlée ;
- absence de QR en double contrôlée.

## 15. Commandes utiles

Tests :

```bash
flutter test
flutter analyze --no-fatal-infos --no-fatal-warnings
```

APK release :

```bash
flutter build apk --release
```

Installation fraîche :

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

Attention : une APK debug et une APK release utilisent des signatures
différentes. Pour remplacer une debug par la release sur le même téléphone, il
faut d'abord vérifier la synchronisation et la sauvegarde, puis désinstaller la
debug. Une installation fraîche sur le téléphone d'un testeur ne pose pas ce
problème.

## 16. Limites connues et prochaines étapes

Avant une diffusion commerciale large :

1. tester l'APK release sur plusieurs vraies marques de téléphones ;
2. tester deux ventes simultanées sur le même produit ;
3. tester plusieurs jours hors ligne ;
4. ajouter des tests d'intégration Drift/Supabase ;
5. ajouter un suivi de crash en production ;
6. préparer politique de confidentialité et conditions d'utilisation ;
7. vérifier les sauvegardes et prévoir une restauration guidée ;
8. mettre à jour `mobile_scanner` : la version actuelle fonctionne, mais
   Flutter signale une incompatibilité Kotlin future ;
9. augmenter `versionCode` à chaque nouvelle release ;
10. générer l'AAB lorsque la publication Google Play sera décidée.

La synchronisation n'est pas un service Android permanent en arrière-plan :
elle se produit au lancement, au retour de connexion et quand l'application
déclenche explicitement une synchronisation.

## 17. Conclusion

La version actuelle est cohérente pour :

- installation directe par APK ;
- démonstration ;
- bêta avec quelques utilisateurs ;
- tests en ligne et hors ligne.

Elle ne doit pas encore être considérée comme définitivement terminée tant que
les tests multi-téléphones et les scénarios de panne réels n'ont pas été
validés.
