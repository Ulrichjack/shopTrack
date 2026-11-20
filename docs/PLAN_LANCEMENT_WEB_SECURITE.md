# ShopTrack — lancement Android + web, sécurité et décisions ouvertes

État au 29 septembre 2026 : plan de travail, **pas** une validation juridique,
une publication ou la preuve que le web fonctionne déjà. Voir aussi
`PREPARATION_GOOGLE_PLAY.md` et `DOSSIER_JURIDIQUE_BROUILLON.md`.

## Décisions de produit

- Marché pilote : boutiques au Cameroun ; bêta gratuite et accompagnée avant
  toute offre payante. Recrutement initial par bouche-à-oreille, sans campagne
  d'influenceurs. Mesurer l'usage et les recommandations avant de fixer un prix.
- Lancement public visé : Android et web utilisable sur iPhone à la même période,
  après une bêta sur de vrais appareils. Le web est **connecté obligatoire** dans
  cette première version ; ne pas annoncer de fonctionnement hors ligne web.
- Un seul backend Supabase, le même compte et les mêmes boutiques pour Android
  et web. Une opération validée et synchronisée sur le web doit apparaître sur
  Android après synchronisation, et inversement. Ce n'est pas un second produit
  ni une seconde base de données.
- Le web doit permettre, si les tests navigateur le confirment, de prendre une
  photo de produit et de scanner QR/codes-barres avec la caméra, avec saisie
  manuelle en secours. Pas de promesse de compatibilité iPhone sans essai réel.
- L'application web peut être ajoutée à l'écran d'accueil de l'iPhone ; cela
  ne constitue pas une publication dans l'App Store Apple.

## Nom et hébergement : décisions avant publication

- **ShopTrack est un nom de travail, pas le nom public validé.** Des services
  actuellement visibles sous ce nom ciblent déjà la gestion de commerces au
  Cameroun. Ne pas créer la fiche Play, acheter le domaine ou déposer une marque
  sous ce nom sans analyse d'antériorité. Proposer des noms courts compréhensibles
  en français et en anglais ; tester leur prononciation auprès de commerçants
  camerounais, puis vérifier marques OAPI/INPI, noms proches, domaines et stores.
- Fixer le nom public avant la première publication Play : le nom affiché peut
  évoluer, mais l'identifiant Android `cm.shoptrack.shoptrack` mérite une décision
  avant sa première mise en production. Ne pas renommer l'identifiant sur une
  application déjà publiée sans plan de migration.
- **Vercel est retenu temporairement pour le frontend Flutter Web** (`build/web`) ;
  Supabase reste le backend partagé avec Android. Aucun déploiement Vercel n'est
  encore attesté. Commencer avec des données fictives, protéger les aperçus et
  vérifier HTTPS, les réécritures des routes SPA et les URL de redirection
  Supabase Auth avant les tests sur iPhone.
- Choisir un plan Vercel compatible **avant** d'ouvrir une bêta à de vraies
  boutiques : Hobby est réservé à l'usage personnel non commercial. Décider
  aussi du domaine public après validation du nom ; ne pas traiter l'URL de
  prévisualisation comme une adresse définitive.

## Points à trancher avant la bêta publique

- Nom public et domaine après recherche d'antériorité ; garder « ShopTrack »
  comme nom de travail jusque-là.
- Plan Vercel autorisé pour l'usage prévu, URL de production et protection des
  aperçus ; séparer clairement les données de test des vraies boutiques.
- Utiliser le projet Supabase de test séparé pour le web et les migrations RLS ;
  y créer uniquement de faux comptes et de fausses boutiques. Ne pas
  modifier la base actuelle pour préparer cet environnement.
- Décider des corrections RLS, du stockage des photos et de la
  sauvegarde/restauration après tests sur ce projet de test.
- Finalisation des textes juridiques et de la suppression effective des
  données avant publication.

## Propriété intellectuelle et nom

- Une idée ou un concept d'application n'a pas, en soi, de « label » protecteur.
  Vérifier d'abord la disponibilité du nom **ShopTrack** dans les pays/classes
  utiles et des domaines, puis envisager un dépôt de marque si pertinent. Le
  code original relève potentiellement du droit d'auteur ; conserver l'historique
  des contributions et vérifier les droits des collaborateurs. Un brevet ne se
  déduit pas d'une application de gestion : il exige une invention technique
  brevetable. Examiner séparément la protection au Cameroun (OAPI).
- La bêta gratuite ne supprime pas les obligations de confidentialité, de
  sécurité et d'information des utilisateurs.

## État technique connu avant la version web

- `lib/core/database/app_database.dart` utilise `dart:io` et `NativeDatabase` ;
  plusieurs écrans et services manipulent `File`. Ils doivent avoir un chemin
  web distinct ou être adaptés. Une simple compilation web ne suffit pas.
- `mobile_scanner` déclare le support web, dont Safari récent. La prise de photo
  passe par `image_picker`, mais le code actuel construit `File(photo.path)` :
  adapter le traitement des octets pour le navigateur. Tester caméra, permission,
  HTTPS, QR imprimé et codes EAN sur un iPhone réel ; garder la saisie manuelle.
- Android demeure local-first. Le web connecté doit afficher un état clair
  « enregistré sur le serveur » ou une erreur, et ne jamais annoncer une vente
  sauvée si l'écriture distante a échoué. Conserver les identifiants et règles
  métier compatibles avec la synchronisation Android.
- La commande locale `flutter build web --no-pub` n'a pas atteint le compilateur :
  le lanceur Flutter fourni ici est bloqué par Snap. Refaire ce test dans un
  environnement Flutter opérationnel après les adaptations.
- Pour le lancement iPhone, utiliser le build Flutter Web JavaScript : la
  documentation Flutter indique que son build WebAssembly ne fonctionne pas
  encore dans les navigateurs iOS.

## Ordre de réalisation et critères de passage

1. **Audit Supabase en lecture seule.** Vérifier l'état réellement déployé des
   migrations, les policies RLS table par table, les grants, les fonctions
   `security definer`, le bucket `product-photos`, les journaux et sauvegardes.
   Tester avec deux boutiques et des comptes patron/vendeur qu'aucune lecture
   ou modification croisée ne passe. Ne jamais placer de clé `service_role`
   dans Android ou le web. Les migrations locales ne prouvent pas l'état distant.
   Première requête préparée : `scripts/audit_supabase_readonly.sql` ; elle
   inventorie RLS, politiques, fonctions privilégiées et visibilité des buckets
   sans écrire. Le 29 septembre, des requêtes ciblées ont été exécutées sur
   la base distante : 22 tables métier avec RLS activé, mais politique de
   transferts trop large (`OR` entre boutiques), photos publiques et prix
   d'achat/profits visibles aux vendeurs. Aucun changement distant appliqué.
2. **Projet de test isolé.** Rejouer les migrations sur un second projet
   Supabase, sans copie des données clients. Configurer la version web de test
   vers ce projet seulement. Vérifier forfait/coût avant création et identifier
   explicitement le projet ciblé avant chaque commande CLI distante ; la base
   actuelle reste en lecture seule jusqu'à une autorisation distincte.
   Le 30 septembre, `shoptrack-staging` (`bjrmapcwfzrrvutozyfx`, `eu-west-1`)
   a été créé sur le plan gratuit. Les migrations du dépôt ne créent pas les
   premières tables : l'instantané du **schéma seul** conservé dans
   `supabase/baselines/` a donc été appliqué comme migration `202609300001`
   depuis un dossier CLI temporaire séparé. Staging contient 22 tables métier
   et aucune donnée utilisateur ou commerciale. La correction RLS des transferts
   (`202609300002`) y est appliquée et testée avec deux propriétaires fictifs
   dans une transaction annulée ; elle n'est **pas** appliquée en production.
   Le 1er octobre, le bucket `product-photos` a été créé sur staging et la
   migration `202610010001` y restreint l'envoi aux propriétaires ; les tests
   SQL fictifs passent, mais **aucun envoi depuis un vrai téléphone n'est encore
   validé**. Le bucket reste public pour les URL de l'Android actuel : les
   photos demeurent accessibles à quiconque possède leur URL. En production,
   le bucket contient 73 objets et n'a pas été modifié.
   Les colonnes `products.buy_price`, `sales.total_profit` et
   `sale_items.buy_price/profit` restent lisibles par le rôle connecté ; le
   vendeur peut donc les obtenir via l'API malgré les écrans Patron. Les
   révoquer maintenant casserait la synchro et le calcul local des ventes :
   prévoir un flux vendeur sans coûts et un calcul de marge côté serveur,
   notamment pour les ventes envoyées après une période hors ligne.
   Auth staging demande une confirmation email, contrairement à la production.
   L'inscription par pseudo-email (`numéro@shoptrack.cm`) ne pourra pas être
   testée normalement avant de désactiver « Confirm email » sur staging.
   Cette désactivation reproduit le comportement actuel, mais ne prouve pas
   que l'inscrit possède réellement le numéro : décider d'une vérification
   de numéro avant une ouverture publique.
   La CLI a refusé une synchronisation globale de configuration ; ne modifier
   que ce réglage dans le tableau de bord, puis le relire via `/auth/v1/settings`.
   Vérifier aussi Edge Functions avant les tests complets. Ne jamais lancer
   `supabase db push` depuis
   la racine liée à la production sans autorisation distincte.

   **Contrôle du 28 octobre sur staging :** 22 tables métier ont RLS actif.
   Les tests transactionnels fictifs de séparation entre deux boutiques, de
   transferts et d'autorisation d'envoi de photos passent. Les grants `anon`
   existent encore sur les tables publiques ; la migration
   `202610280001_revoke_anon_public_grants.sql` est préparée mais **pas encore
   appliquée** pendant le test manuel. Les prix d'achat et bénéfices restent
   accessibles aux vendeurs via l'API, et le bucket photo reste public. Ces
   deux points nécessitent une adaptation de l'app avant de durcir les accès.
3. **Prototype web minimal.** Faire fonctionner connexion, sélection boutique,
   lecture produits, création/vente et retour vers Android ; adapter `dart:io`,
   base locale et photos sans dupliquer les données. Vérifier les erreurs réseau
   et la session après fermeture/réouverture du navigateur.
4. **Caméra et médias.** Tester scan QR/EAN et capture photo sur Safari iPhone,
   Chrome Android et au moins un navigateur bureau, via HTTPS. Prévoir refus de
   permission, absence de caméra et saisie manuelle ; vérifier la visibilité
   réelle des photos stockées.
5. **Conformité et publication.** Finaliser les textes encore en brouillon,
   mettre en œuvre le traitement réel des demandes de suppression, vérifier
   hébergement/transferts et contrats, puis préparer les exigences Google Play.
6. **Bêta puis public.** Quelques boutiques volontaires, données de test puis
   vraies données avec accord et support ; tests web→Android et Android→web,
   ventes simultanées, refus serveur, réouverture, sauvegarde/restauration.
   Publier seulement après correction des problèmes bloquants.

## Tests à chaque chantier, puis tests globaux

| Moment | Vérification minimale |
|---|---|
| Après une correction Supabase | Test avec deux boutiques et deux rôles, accès croisé refusé, actions autorisées intactes sur Android |
| Après chaque adaptation web | Compilation web JavaScript, connexion et opération concernée dans le navigateur ; régression Android sur l'écran partagé |
| Après photo/scan | Safari iPhone réel, Chrome Android, permission refusée, code illisible, saisie manuelle |
| Avant bêta | Parcours complet Android hors ligne → synchronisation → web ; web → Android ; ventes simultanées, erreur réseau et reconnexion |
| Avant publication | `flutter analyze`, `flutter test`, tests réels Android et iPhone, règles légales et suppression de compte finalisées |

### Passage obligatoire sur téléphone Android réel

Un test SQL, un émulateur ou `flutter test` ne valent pas validation sur un
téléphone. Le flavor Android **staging isolé** utilise l'identifiant
`cm.shoptrack.shoptrack.staging`, le nom `ShopTrack TEST` et la base Supabase
staging ; le flavor production conserve `cm.shoptrack.shoptrack`. Android isole
ainsi SQLite, Auth et les sauvegardes dans le dossier privé de chaque app.
Changer seulement l'URL Supabase d'un APK existant risquerait d'envoyer son
cache de production vers staging. Ne jamais installer un APK de test par-dessus
l'app réelle d'un utilisateur.

Le 28 octobre, l'APK **debug** staging a été recompilé avec le choix de photo
dans la galerie et l'import/export CSV du catalogue ;
`cm.shoptrack.shoptrack.staging` a été revérifié avec `aapt`. Le 1er octobre,
les APK debug staging et production avaient déjà été compilés ;
leurs identifiants et noms ont été vérifiés avec `aapt`. Pour reconstruire
l'APK staging, utiliser `bash scripts/construire_staging_android.sh` après
connexion à la CLI Supabase ; il récupère uniquement la clé publique `anon`.
Le résultat est `build/app/outputs/flutter-apk/app-staging-debug.apk`.
Cet APK n'est ni signé pour Google Play ni une preuve de fonctionnement sur
téléphone. Avant toute inscription de test, désactiver **Confirm email** dans
le projet staging uniquement ; ne pas modifier la production.

Sur un téléphone Android réel appartenant au projet, installer explicitement
cet APK de test après le test manuel en cours avec l'ancienne version.
Avec des comptes fictifs : inscription et
reconnexion, ajout d'un produit avec photo, affichage de cette photo après
redémarrage, scan QR/EAN et saisie manuelle, vente puis fermeture/réouverture,
mode avion puis synchronisation, et refus d'accès du vendeur aux actions Patron.
Sur un second téléphone, vérifier la synchronisation entre deux boutiques et
les transferts. Relever modèle, version Android, version/commit de l'APK,
résultat et erreurs pour chaque scénario. Toute anomalie reproductible est
bloquante pour une mise en production de la correction concernée. Le 28 octobre,
des parcours automatisés ont été effectués sur le téléphone de test, mais la
checklist manuelle complète reste à faire : voir
`docs/CHECKLIST_TEST_MANUEL_STAGING.md`.

Une suite globale uniquement à la fin serait trop tardive : chaque lot doit
passer ses propres tests, puis le parcours complet sur les deux plateformes.

## Mesure d'usage : pas besoin d'un outil lourd maintenant

- Commencer avec des **comptages agrégés** : nouveaux comptes par semaine,
  boutiques actives sur 7 jours, ventes synchronisées sur 7 jours, erreurs de
  synchronisation et délai de résolution. Les dates de vente mesurent l'activité
  métier, pas toutes les ouvertures de l'application ; `last_sign_in_at` mesure
  une connexion, pas l'usage régulier.
- Interroger ces données côté administration Supabase avec accès restreint,
  sans afficher noms/numéros dans un tableau public ni embarquer une clé admin
  dans l'app. Ne pas installer un SDK de pistage marketing avant d'avoir défini
  son utilité, son information aux utilisateurs et sa configuration RGPD.
- Aucun chiffre de trafic récent n'est attesté dans ce dépôt. L'accès en direct
  au projet Supabase doit être vérifié avant d'en annoncer un.

## Sources à revérifier au moment de décider

- [INPI — protection d'une idée et de ses formes](https://www.inpi.fr/sites/default/files/proteger_ses_creations.pdf)
- [mobile_scanner — support web et limites](https://pub.dev/packages/mobile_scanner)
- [Flutter — compatibilité WebAssembly sur iOS](https://docs.flutter.dev/platform-integration/web/wasm)
- [Vercel — conditions du plan Hobby](https://vercel.com/docs/plans/hobby)
- [Supabase — URL de redirection Auth](https://supabase.com/docs/guides/auth/redirect-urls)
- [OAPI — recherche d'antériorité](https://oapi.int/proteger-la-pi/recherche-danteriorite/)
