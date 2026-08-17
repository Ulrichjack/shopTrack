# ShopTrack — Plan de corrections et d'améliorations

## État d'implémentation — 27 juillet 2026

Les corrections décrites dans ce document ont été implémentées dans le projet :

- scanner avec erreurs explicites, reprise caméra et saisie manuelle ;
- recherche locale puis Supabase après le scan ;
- synchronisation fusionnée, file visible et stock distant idempotent ;
- calcul de clôture unifié et doublons journaliers évités ;
- manques, surplus et résultat ajusté visibles dans le bilan et le PDF ;
- PIN non stocké en clair et routes Patron protégées ;
- historique local, sauvegarde JSON et configuration de signature release ;
- tests automatiques du calcul de caisse.

Restent à effectuer hors du code :

1. appliquer la migration
   `supabase/migrations/202607270001_secure_sync.sql` sur Supabase ;
2. créer et conserver la clé Android de production ;
3. installer le même APK sur plusieurs téléphones et exécuter les essais réels
   caméra, hors ligne et simultanés.

## 1. Objectif du document

Ce document regroupe les problèmes constatés dans la première version de
ShopTrack, leurs causes probables et les modifications recommandées.

Les priorités principales sont :

1. rendre le scanner QR fiable sur plusieurs téléphones ;
2. corriger et afficher les écarts de caisse dans le bilan ;
3. fiabiliser la synchronisation entre plusieurs appareils ;
4. protéger les données comptables et le stock ;
5. ajouter des tests et préparer une vraie version de production.

---

## 2. État actuel du projet

ShopTrack est une application Flutter utilisant :

- Supabase pour l'authentification et les données distantes ;
- Drift/SQLite pour les données locales ;
- Riverpod pour la gestion d'état ;
- `mobile_scanner` pour la lecture des QR et codes-barres ;
- `qr_flutter` pour générer les QR ;
- une file locale pour fonctionner hors connexion.

### Points positifs

- architecture organisée par fonctionnalités ;
- fonctionnement hors ligne déjà commencé ;
- gestion des produits, ventes, caisse et clôtures ;
- génération de bilans mensuels et de PDF ;
- séparation entre mode Patron et mode Vendeur ;
- calcul et stockage de l'écart de caisse déjà présents.

### État des vérifications

La commande `flutter analyze` signale 57 problèmes, principalement :

- un test obsolète qui ne compile plus ;
- plusieurs usages de `BuildContext` après une opération asynchrone ;
- des API Flutter dépréciées ;
- des imports inutilisés ;
- de nombreux `print()` utilisés comme système de journalisation.

La commande `flutter test` échoue parce que le test généré par défaut utilise
encore une classe `MyApp` qui n'existe plus.

---

## 3. Priorité critique — Scanner QR indisponible sur certains téléphones

### 3.1 Symptôme observé

Sur le téléphone concerné :

- l'écran du scanner reste noir ;
- un point d'exclamation blanc apparaît au centre ;
- l'icône du flash est barrée ;
- aucun QR ne peut être lu.

Ce symbole est l'affichage d'erreur par défaut de `mobile_scanner`. Il signifie
que la caméra du scanner n'a pas pu être initialisée. Ce n'est pas une erreur
dans le contenu du QR.

### 3.2 Causes possibles

1. Permission caméra refusée sur le téléphone.
2. Ancien APK installé avant les dernières modifications Android.
3. Incompatibilité liée à la rétrogradation de `mobile_scanner` de `7.2.0`
   vers `5.2.3`.
4. Caméra laissée dans un mauvais état après une mise en arrière-plan.
5. Caméra déjà utilisée par une autre application.
6. Erreur native masquée par l'absence de message explicite.
7. Permission iOS absente dans `Info.plist`.

### 3.3 Fichiers concernés

- `lib/features/products/presentation/screens/barcode_scanner_screen.dart`
- `android/app/src/main/AndroidManifest.xml`
- `android/gradle.properties`
- `ios/Runner/Info.plist`
- `pubspec.yaml`
- `pubspec.lock`

### 3.4 Modifications recommandées

#### A. Afficher l'erreur réelle

Ajouter un `errorBuilder` au widget `MobileScanner`.

L'écran doit distinguer au minimum :

- permission refusée ;
- caméra indisponible ;
- appareil non compatible ;
- contrôleur non initialisé ;
- erreur inconnue.

Il doit proposer :

- un bouton **Réessayer** ;
- un bouton **Ouvrir les paramètres** si la permission est refusée ;
- une explication claire en français.

#### B. Gérer le cycle de vie de la caméra

L'écran du scanner doit :

- implémenter `WidgetsBindingObserver` ;
- arrêter la caméra lorsque l'application devient inactive ;
- redémarrer la caméra au retour dans l'application ;
- arrêter l'écoute après la détection d'un code ;
- libérer correctement le contrôleur à la fermeture.

Cela évite les écrans noirs après :

- une demande de permission ;
- un changement d'application ;
- le verrouillage du téléphone ;
- plusieurs ouvertures successives du scanner.

#### C. Stabiliser la version du scanner

Ne pas conserver une rétrogradation sans justification.

Procédure recommandée :

1. choisir une version récente compatible avec le Flutter utilisé ;
2. adapter le code aux changements d'API de cette version ;
3. exécuter `flutter clean` ;
4. exécuter `flutter pub get` ;
5. reconstruire complètement l'APK ;
6. tester le même APK sur tous les téléphones.

#### D. Compléter les permissions

Android doit conserver :

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

Pour iOS, ajouter dans `ios/Runner/Info.plist` :

```xml
<key>NSCameraUsageDescription</key>
<string>ShopTrack utilise la caméra pour scanner les codes des produits.</string>
```

Si la galerie est utilisée pour lire un QR, ajouter également la permission
photothèque appropriée.

#### E. Améliorer l'expérience de scan

- limiter les formats aux formats réellement utilisés ;
- utiliser en priorité la caméra arrière ;
- ajouter un bouton pour changer de caméra ;
- permettre un léger zoom ;
- arrêter le scanner après la première détection ;
- vibrer ou jouer un signal court après une lecture réussie ;
- permettre la saisie manuelle du code si la caméra échoue.

### 3.5 Validation attendue

Tester au minimum :

- permission acceptée au premier lancement ;
- permission refusée puis réactivée dans les paramètres ;
- ouverture et fermeture répétées du scanner ;
- retour après mise en arrière-plan ;
- téléphone sans flash ;
- téléphone Android ancien ou peu puissant ;
- plusieurs marques de téléphones ;
- QR affiché sur un autre écran ;
- code-barres physique avec faible luminosité.

Le test est réussi si :

- la caméra s'affiche ;
- l'erreur réelle est visible en cas d'échec ;
- le bouton Réessayer fonctionne ;
- le code est détecté une seule fois ;
- l'écran renvoie correctement la valeur détectée.

---

## 4. Priorité critique — Produit introuvable sur un deuxième téléphone

### 4.1 Cause actuelle

Après le scan, l'application cherche le code uniquement dans la liste locale
déjà chargée en mémoire.

Si le téléphone B n'a pas téléchargé le produit créé sur le téléphone A, le QR
peut être lu correctement mais l'application affiche :

> Aucun produit trouvé avec ce code

### 4.2 Problèmes de synchronisation constatés

- `processQueue()` est souvent appelé sans `await` ;
- un produit peut donc ne pas être encore envoyé à Supabase ;
- le téléchargement distant ne rafraîchit pas toujours `productProvider` ;
- l'état Riverpod peut garder une ancienne liste en mémoire ;
- le scanner ne tente pas une recherche distante en cas d'absence locale ;
- la synchronisation efface les tables locales avant de les remplir ;
- un téléchargement peut entrer en conflit avec des opérations locales en attente.

### 4.3 Comportement recommandé

Après la lecture d'un code :

1. normaliser la valeur (`trim`, format cohérent) ;
2. rechercher dans la base locale ;
3. si le produit est absent et Internet disponible, rechercher dans Supabase ;
4. si le produit est trouvé, le mettre en cache local ;
5. actualiser `productProvider` ;
6. ouvrir l'ajout au panier ;
7. sinon afficher un message précis.

Exemples de messages :

- « QR lu, mais produit non synchronisé » ;
- « Produit absent de cette boutique » ;
- « Connexion nécessaire pour rechercher ce produit » ;
- « Ce code appartient déjà à un autre produit ».

### 4.4 Contraintes de données recommandées

Ajouter côté Supabase une contrainte unique :

```text
(shop_id, barcode)
```

Cela doit empêcher deux produits de la même boutique d'utiliser le même code.

### 4.5 Écran d'état de synchronisation

Ajouter un petit indicateur présentant :

- En ligne / Hors ligne ;
- dernière synchronisation réussie ;
- nombre d'opérations en attente ;
- dernière erreur ;
- bouton **Synchroniser maintenant**.

---

## 5. Priorité critique — Écart de caisse absent du bilan

### 5.1 Diagnostic confirmé

L'écart est calculé avec :

```text
écart = caisse physique - caisse calculée
```

Il est ensuite :

- enregistré dans Drift ;
- placé dans la file de synchronisation ;
- envoyé à Supabase ;
- additionné dans `totalCashGap`.

Cependant, il n'est affiché ni dans :

- les cartes du bilan mensuel ;
- le tableau journalier ;
- le PDF.

### 5.2 Modifications d'affichage

Ajouter dans le bilan :

- caisse calculée totale ;
- caisse physique totale ;
- manques cumulés ;
- surplus cumulés ;
- écart net ;
- nombre de jours avec anomalie.

Ajouter dans le tableau journalier :

- caisse attendue ;
- caisse physique ;
- écart ;
- note de clôture.

Ajouter les mêmes informations dans le PDF.

### 5.3 Ne pas masquer les anomalies

Une simple somme signée peut masquer les problèmes.

Exemple :

```text
Jour 1 : -10 000 FCFA
Jour 2 : +10 000 FCFA
Écart net : 0 FCFA
```

Même si l'écart net est nul, il existe deux anomalies.

Le bilan doit donc calculer séparément :

```text
Manques cumulés
Surplus cumulés
Écart net
Somme absolue des écarts
Nombre de jours avec écart
```

### 5.4 Bénéfice et écart

Conserver deux indicateurs différents :

```text
Bénéfice opérationnel = marge brute - dépenses
Résultat ajusté de caisse = bénéfice opérationnel + écart
```

Cette séparation évite de présenter automatiquement un surplus inexpliqué
comme un véritable bénéfice commercial.

---

## 6. Priorité critique — Incohérence du solde du matin

### 6.1 Problème

Le tableau de bord prend uniquement le solde du matin le plus récent.

Au moment de la clôture, `closeDay()` additionne tous les mouvements de type
`morning_balance`.

S'il existe plusieurs saisies le même jour :

- l'écran montre un premier montant de caisse calculée ;
- la sauvegarde recalcule un autre montant ;
- l'écart affiché peut être différent de l'écart enregistré.

### 6.2 Correction recommandée

Créer un service pur et central :

```text
CashClosingCalculator
```

Il doit être utilisé :

- par le tableau de bord ;
- par l'écran de clôture ;
- par `closeDay()` ;
- par les tests.

La règle métier doit être unique :

- soit un seul solde du matin autorisé par jour ;
- soit le dernier solde remplace le précédent ;
- ne jamais additionner plusieurs corrections de solde.

Ajouter une contrainte logique empêchant plusieurs soldes matinaux actifs pour
la même boutique et la même date.

### 6.3 Cas limite constaté (2026-08-09)

`morningBalance == 0` sert à la fois de valeur métier valide (caisse vraiment
vide le matin) et de indicateur "pas encore saisi" dans
`dashboard_screen.dart` (`_checkAlerts`). Une boutique qui saisit
volontairement 0 verra donc la boîte de dialogue obligatoire réapparaître en
boucle, puisque le calcul reste à 0 après l'enregistrement. Non corrigé —
nécessite un indicateur "saisi aujourd'hui" séparé du montant lui-même.

---

## 7. Priorité haute — Fiabilité de la clôture

### Problèmes à corriger

- la clôture locale utilise toujours un nouvel UUID ;
- une deuxième clôture du même jour peut créer un doublon local ;
- les lectures avec `getSingleOrNull()` peuvent échouer s'il existe plusieurs lignes ;
- l'écran peut revenir à l'accueil même si la clôture a échoué ;
- les montants contenant un espace ou une virgule peuvent ne pas être compris ;
- une égalité exacte sur des `double` est fragile.

### Recommandations

- utiliser un `upsert` local par boutique et date ;
- rendre `(shop_id, closing_date)` unique localement et dans Supabase ;
- afficher un chargement pendant la sauvegarde ;
- naviguer uniquement après confirmation réelle ;
- présenter les erreurs sans les masquer ;
- accepter et normaliser `10 000`, `10000` et `10 000,00` ;
- utiliser des montants entiers en FCFA lorsque les décimales ne sont pas nécessaires.

---

## 8. Priorité haute — Synchronisation hors ligne

### Risques actuels

- suppression complète des tables locales pendant un téléchargement ;
- opérations locales encore en attente potentiellement écrasées ;
- appels réseau lancés sans attendre leur résultat ;
- absence de reprise structurée après erreur ;
- absence d'identifiant d'erreur ou de nombre de tentatives ;
- conflits possibles entre plusieurs téléphones ;
- stocks mis à jour par lecture puis écriture, sans opération atomique.

### Architecture recommandée

Ordre de synchronisation :

```text
1. Détecter une vraie connexion Internet
2. Envoyer la file locale
3. Confirmer chaque opération côté serveur
4. Télécharger les nouveautés
5. Fusionner sans supprimer les opérations locales en attente
6. Rafraîchir tous les providers concernés
```

Ajouter dans la file :

- statut ;
- nombre de tentatives ;
- dernière erreur ;
- date de dernière tentative ;
- identifiant idempotent.

### Stock multi-téléphone

La mise à jour de stock doit être atomique côté Supabase.

Éviter :

```text
lire quantité → calculer → réécrire quantité
```

Préférer :

```text
transaction/RPC serveur → décrémenter si stock suffisant
```

Le serveur doit refuser une vente lorsque le stock est insuffisant.

---

## 9. Priorité haute — Sécurité

### Mode Patron

Le PIN est enregistré en clair dans `SharedPreferences`.

De plus, cacher le bouton Bilan ne protège pas réellement la route `/bilan`.

Recommandations :

- stocker le secret dans le stockage sécurisé du téléphone ;
- ne jamais conserver le PIN en clair ;
- protéger les routes Patron avec une vraie vérification ;
- vérifier les rôles côté Supabase/RLS ;
- ne pas considérer une restriction visuelle comme une autorisation.

### Supabase

Vérifier les politiques RLS pour toutes les tables :

- un utilisateur ne doit lire que sa boutique ;
- un vendeur ne doit pas modifier les paramètres sensibles ;
- les clôtures ne doivent pas pouvoir être modifiées sans autorisation ;
- les stocks doivent être mis à jour par une opération serveur contrôlée.

Le fichier `lib/supabase_config.dart` est actuellement suivi par Git malgré un
ancien commit indiquant son retrait. Une clé publique Supabase est intégrée à
l'application par nature, mais la sécurité doit entièrement reposer sur RLS et
non sur la confidentialité de cette clé.

### Version de production

La version release Android utilise encore la clé de signature debug.

Avant publication :

- créer un keystore de production ;
- conserver ses mots de passe hors de Git ;
- configurer la signature release ;
- protéger et sauvegarder le keystore ;
- incrémenter `versionName` et `versionCode`.

---

## 10. Priorité haute — Tests

Remplacer le test compteur Flutter obsolète.

### Tests unitaires indispensables

#### Calcul de caisse

- aucune vente et aucun retrait ;
- solde du matin seulement ;
- ventes et retraits ;
- caisse parfaite ;
- manque ;
- surplus ;
- correction du solde du matin ;
- plusieurs saisies du solde ;
- clôture en retard.

#### Bilan

- total des ventes ;
- total des dépenses ;
- bénéfice opérationnel ;
- manques cumulés ;
- surplus cumulés ;
- écart net ;
- écarts qui se compensent ;
- mois sans clôture.

#### Synchronisation

- création hors ligne puis reconnexion ;
- erreur réseau temporaire ;
- opération envoyée une seule fois ;
- produit créé sur le téléphone A et lu sur B ;
- conflit de stock entre deux téléphones ;
- données locales en attente pendant un téléchargement.

#### Scanner

- permission accordée ;
- permission refusée ;
- caméra indisponible ;
- code détecté ;
- détection multiple ;
- produit local trouvé ;
- recherche distante de secours ;
- code inconnu.

### Tests manuels sur téléphones

Maintenir une matrice :

| Appareil | Android/iOS | Version OS | Caméra | Scan | Synchro |
|---|---:|---:|---|---|---|
| Téléphone principal |  |  |  |  |  |
| Téléphone secondaire |  |  |  |  |  |
| Téléphone ancien |  |  |  |  |  |

---

## 11. Priorité moyenne — Qualité et maintenance

### Journalisation

Remplacer les `print()` par un système de logs structuré :

- niveau debug ;
- niveau information ;
- avertissement ;
- erreur avec contexte ;
- désactivation des données sensibles en production.

### Documentation

Remplacer le README Flutter par défaut avec :

- présentation de ShopTrack ;
- prérequis ;
- configuration Supabase ;
- lancement développement ;
- construction APK ;
- architecture ;
- fonctionnement hors ligne ;
- commandes de test ;
- procédure de publication ;
- limites connues.

### Nettoyage du code

- corriger tous les avertissements de `flutter analyze` ;
- remplacer les API dépréciées ;
- retirer les imports inutilisés ;
- corriger les usages asynchrones de `BuildContext` ;
- centraliser les parseurs de montants ;
- supprimer les commentaires temporaires devenus inutiles.

---

## 12. Dette d'architecture (relevé du 2026-08-13, 3 modules livrés)

L'architecture a tenu à trois modules cohabitants — c'est son vrai test, et
elle le passe. Mais elle repose beaucoup sur des **règles écrites** plutôt que
sur des garde-fous techniques. Les quatre points ci-dessous sont classés par
**moment où il faut agir**, pas par gravité théorique.

### À faire AVANT le multi-boutique (B7) — bloquant

**L'hypothèse « une seule boutique » est enfouie partout.**
`shop_members...single()` dans `sync_service.dart`, et surtout
`prefs.getString('cached_shop_id')` lu directement dans une douzaine de
fichiers. Passer au multi-boutique sans centraliser cet accès obligerait à
modifier tous ces endroits — avec la quasi-certitude d'en oublier un, qui
continuerait silencieusement à travailler sur la mauvaise boutique. C'est le
pire type de bug : aucune erreur affichée, des données écrites au mauvais
endroit.

→ Centraliser derrière un `activeShopProvider` unique **avant** de commencer
B7. Environ une heure, contre un bug très difficile à diagnostiquer ensuite.

### À faire quand on retouche la synchro — préventif

**`sync_service.dart` est un goulot.** Toute la synchro passe par un `switch`
qui grossit à chaque module, et c'est là que les trois bugs d'intégrité du
2026-08-10 sont apparus. La règle « ajouter la colonne aux deux côtés du
pull » est documentée dans `CLAUDE.md`, mais elle repose sur la discipline.

→ Plutôt qu'un refactoring risqué, **un test qui compare les tables poussées
et les tables tirées** et échoue si une table est envoyée sans être
retéléchargée. Beaucoup moins cher, et ça transforme une règle écrite en
garde-fou automatique.

**FAIT le 2026-08-14** — `test/sync_pull_coverage_test.dart` : toute table
Drift absente de `pullDataFromSupabase()` fait échouer le test, exceptions
documentées dans le test lui-même. Écrit après avoir trouvé le quatrième bug
de cette famille : `stock_movements` était poussée par le RPC mais jamais
tirée, donc le rapport de période perdait ses recharges après réinstallation
et annonçait un bénéfice surévalué. Le refactoring de `sync_service.dart`
reste inutile tant que ce test tient.

### À surveiller, sans urgence

**Les tests couvrent les calculs, pas les parcours.** 31 tests pour ~14 000
lignes, tous unitaires sur des fonctions pures. Aucun ne simule « je vends
hors ligne puis je synchronise » — or c'est exactement là que se logeaient
les bugs réels, tous trouvés à la main sur téléphone. Le test manuel a été
efficace ; un test d'intégration coûterait cher pour un gain incertain tant
qu'il y a peu de contributeurs.

**`dashboard_provider.dart` fait trop de choses** : synchro, calcul de la
journée, clôture, réouverture, détection de journée oubliée. Il grossit à
chaque fonctionnalité. À découper **le jour où on y touche pour autre chose**,
pas avant — un découpage pour lui-même ne rapporterait rien aujourd'hui.

---

## 13. Idées d'amélioration fonctionnelle

### Court terme

- bouton de synchronisation manuelle ;
- indicateur du nombre d'opérations en attente ;
- recherche d'un produit par code saisi manuellement ;
- affichage détaillé des écarts ;
- filtre des jours avec anomalie ;
- export PDF enrichi ;
- version de l'application visible dans le profil ;
- corriger le contenu masqué par les boutons/barre de navigation en bas de
  certains écrans (safe area insuffisante — signalé sur plusieurs tailles
  d'écran, 2026-08-09) ;
- rendre la sauvegarde JSON manuelle du profil réellement utile au client
  (partage/export vers WhatsApp, mail, Drive...) ou la retirer de l'interface
  — aujourd'hui le fichier est écrit dans un dossier privé de l'appli, non
  accessible sans outil technique (la sauvegarde automatique avant
  déconnexion, elle, reste utile en interne et n'est pas concernée).

### Moyen terme

- gestion réelle des employés et rôles ;
- historique d'audit des modifications ;
- alertes de stock faible ;
- inventaire physique et écarts de stock ;
- annulation contrôlée d'une vente ;
- impression ou partage de reçu ;
- sauvegarde et restauration contrôlées ;
- tableau de bord multi-boutiques ;
- abonnement payant par boutique (monétisation) — voir
  `docs/PLAN_MODULES_CLIENTS.md` pour le lien avec l'activation des modules A/B.

### Long terme

- **refonte visuelle inspirée de WhatsApp** (direction assumée, décidée le
  2026-08-11) : très peu de couleurs (vert/blanc/gris), tout en listes au
  rythme constant (icône · titre gras · sous-titre gris · action à droite),
  aucune décoration inutile. Objectif : familiarité — le commerçant retrouve
  les réflexes de l'app qu'il utilise déjà tous les jours, ce qui réduit le
  temps d'apprentissage. **Ne pas** reprendre la métaphore de conversation
  (bulles) : ShopTrack manipule des chiffres, pas des messages.
  À faire **après** la validation terrain du module A, en une refonte
  cohérente plutôt qu'écran par écran. Défauts actuels à corriger à cette
  occasion : hiérarchie visuelle trop plate sur le tableau de bord (le
  montant en caisse doit dominer), deux styles qui cohabitent (cartes
  ombrées vs champs bordés), états vides pauvres, Bilan trop dense ;
- synchronisation temps réel Supabase ;
- tableau de bord Web pour le patron ;
- lecture de codes EAN/UPC et génération d'étiquettes ;
- statistiques par produit, vendeur et période ;
- prévisions de rupture de stock ;
- suivi des achats fournisseurs ;
- notifications automatiques ;
- mode caisse sur tablette.

---

## 14. Ordre d'implémentation conseillé

### Phase 1 — Stabilisation

1. Corriger le scanner et afficher les erreurs.
2. Stabiliser la version de `mobile_scanner`.
3. Corriger le calcul unique de clôture.
4. Afficher les écarts dans le bilan et le PDF.
5. Corriger le test obsolète.

### Phase 2 — Multi-téléphone

1. Attendre les envois de la file.
2. Rafraîchir Riverpod après téléchargement.
3. Ajouter la recherche Supabase après scan.
4. Ajouter les contraintes d'unicité.
5. Rendre les mises à jour de stock atomiques.

### Phase 3 — Sécurité et production

1. Vérifier les politiques RLS.
2. Sécuriser le mode Patron.
3. Configurer la signature Android release.
4. Ajouter les tests de non-régression.
5. Documenter et versionner les APK.

### Phase 4 — Améliorations

1. État de synchronisation.
2. Inventaire et écarts de stock.
3. Rapports enrichis.
4. Audit et statistiques.

---

## 15. Critères avant une mise en production

La version pourra être considérée comme prête lorsque :

- le scanner fonctionne sur tous les téléphones de test ;
- une erreur caméra produit un message compréhensible ;
- un produit créé sur A est scannable sur B ;
- aucune vente n'est envoyée deux fois ;
- une vente simultanée ne produit pas de stock négatif ;
- l'écart affiché avant clôture est identique à l'écart enregistré ;
- le bilan et le PDF affichent les écarts ;
- les jours avec manque et surplus ne se masquent pas ;
- les routes Patron sont réellement protégées ;
- les politiques Supabase sont vérifiées ;
- `flutter analyze` ne contient plus d'erreur ;
- tous les tests passent ;
- l'APK release possède une signature de production ;
- chaque APK possède un numéro de version unique.

## Dette d'interface — relevée le 16/08/2026, à traiter après B7 et B8

Retours du terrain sur téléphone réel. Rien ici n'est faux : ce sont des
frictions d'usage. Elles sont groupées parce qu'elles se corrigent bien
ensemble, une fois le multi-boutique posé.

### L'écran perd la moitié de sa hauteur

Les barres de titre et les marges mangent près de 50 % de l'écran sur un
petit appareil. Deux choses à faire :

- **Une barre qui se rétracte au défilement** (`SliverAppBar` avec
  `floating`/`snap`), pour que la liste occupe l'écran dès qu'on descend.
  Aujourd'hui le titre reste figé et vole la place utile.
- **Réduire les marges** : nos écrans utilisent des paddings de 20 à 24 px
  empilés (page + carte + tuile). Sur un Pixel 4a, cela laisse moins de la
  moitié de la largeur au contenu.

### La navigation depuis le rapport est un cul-de-sac

- Le bouton retour **quitte l'application** au lieu de revenir en arrière.
- Impossible de rejoindre Accueil, Stock ou Inventaire depuis le rapport.

Cause probable : `/inventory-report` est atteint par l'onglet du bas, qui
utilise `context.go()` — donc sans pile de navigation. À reprendre avec la
barre d'onglets plutôt qu'en ajoutant un bouton retour.

### Pas de retour explicite sur « Déclarer une perte »

La feuille se ferme au glissement vers le bas, mais rien ne le dit. Il faut un
bouton de fermeture visible.

### La mise à jour paraît lente

Corrigé pour le rapport (voir plus bas), mais le ressenti général reste :
l'app attend la fin de la synchro réseau avant de rafraîchir l'écran, alors
que l'écriture locale est déjà faite. L'affichage devrait suivre l'écriture
locale, la synchro n'étant qu'un rattrapage en arrière-plan.

### Deux synchros à chaque lancement

Visible dans les logs : deux `[SYNC] téléchargement terminé` à une seconde
d'intervalle à chaque démarrage. Deux providers demandent le pull en parallèle.
Sans gravité, mais c'est du réseau et de la batterie pour rien.

### Le sélecteur de périodes va s'allonger sans fin

Un commerçant qui compte tous les mois aura 12 périodes après un an, 60 après
cinq. Une liste déroulante de 60 lignes est inutilisable, et elle grossit
pour toujours.

Ce qu'il consulte réellement : la période en cours, parfois la précédente pour
comparer, très rarement un mois d'il y a deux ans. La liste doit donc suivre
cet usage — les dernières périodes accessibles d'un geste, le reste replié et
groupé par année. Ne pas se contenter d'ajouter une barre de défilement : le
problème n'est pas la place, c'est qu'on ne retrouve rien dans 60 dates.

### Décisions de design prises le 16/08, à appliquer dans la refonte

- **Une barre d'onglets partout, y compris sur le rapport.** Plutôt qu'un
  bouton retour bricolé : si Accueil, Stock et Inventaire restent atteignables,
  le problème du cul-de-sac disparaît de lui-même. Le rapport n'est pas un
  écran de détail, c'est une destination.
- **Le sélecteur de période devient un écran de recherche**, ouvert par le bas,
  liste du plus récent au plus ancien. Un menu déroulant ne tient pas la
  distance : douze périodes par an, soixante en cinq ans.
- **Normaliser les composants.** Deux styles cohabitent (cartes ombrées contre
  champs bordés), et les boutons de confirmation ne tiennent pas correctement
  dans leur zone. Un seul vocabulaire visuel : un style de carte, un style de
  bouton, un style de champ — décidés une fois et réutilisés.

Ces trois points rejoignent la refonte WhatsApp du §13 : ils s'appliquent
**ensemble**, pas écran par écran, sinon on fabrique une app à deux visages.

### Attentes sans retour visuel

La déconnexion vérifie la file de synchronisation avant de partir : sur un
réseau lent, l'écran reste figé plusieurs secondes sans rien dire, et le
commerçant appuie une seconde fois. Il faut un indicateur pendant l'opération,
puis la bascule vers l'écran de connexion.

Même règle partout : **toute action qui attend le réseau doit le montrer**.
À passer en revue lors de la refonte — enregistrement d'une vente, d'un
comptage, création d'un vendeur, changement de boutique.

### Après un changement de compte, chaque boutique se retélécharge à la visite

Le téléchargement ne rapporte que la **boutique active**. Un patron qui change
de compte doit donc visiter ses trois boutiques une à une pour retrouver leurs
données. Ce n'est pas une perte — tout est sur le serveur — mais l'attente se
répète. Précharger les autres boutiques en arrière-plan après une bascule de
compte réglerait la friction.

### Corrigés immédiatement le 16/08 — c'étaient des bugs, pas du design

- **Une perte déclarée n'apparaissait qu'après redémarrage** : `declareLoss`
  n'invalidait pas `inventoryReportProvider`. Idem pour la recette du jour.
- **Le mode simple clignotait à la reconnexion** : `shopSettingsProvider`
  attendait la réponse de Supabase avant de rendre quoi que ce soit. Pendant
  ce temps les écrans se construisaient sur les valeurs par défaut — donc en
  mode simple — et basculaient en inventaire une seconde plus tard. Le cache
  local est désormais lu en premier, le réseau ne fait que corriger ensuite.
- **Le mode de la boutique était perdu à chaque connexion** : le commerçant
  devait retourner activer son module. `shopSettingsProvider` se construisait
  avant que `cached_shop_id` soit écrit et gardait les valeurs par défaut ;
  il n'était invalidé qu'à la déconnexion, jamais à la connexion.
