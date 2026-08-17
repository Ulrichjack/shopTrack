# Pièges connus — à vérifier avant de livrer

Liste des bugs réellement rencontrés sur ShopTrack, avec ce qui les a trahis.
À relire avant toute livraison et avant toute revue de code touchant la
synchro, un mapping ou un écran de saisie.

**Le point commun de presque tous** : ils ne plantent pas. L'app continue de
fonctionner et affiche un chiffre faux. Aucun n'a été trouvé par
`flutter analyze` ni par les tests unitaires existants — tous par la lecture de
la base SQLite du téléphone ou par un scénario joué en vrai.

---

## 1. Champ oublié dans un mapping

**Symptôme** : une donnée existe en base mais disparaît de l'app, ou revient
vide, ou s'efface toute seule quelques secondes après avoir été écrite.

| Cas | Conséquence |
|-----|-------------|
| `sale_items.cycle_id` absent du pull | effacé quelques secondes après la vente, invisible sur un seul téléphone |
| `stock_movements` poussée mais jamais tirée | le rapport perdait ses recharges → faux « tu as encaissé plus », bénéfice surévalué |
| `unit` absent de `ProductEntity` | **modifier un produit effaçait son unité** — l'écran pré-remplissait un champ toujours vide |

**Règle** : une table synchronisée se déclare **à un seul endroit**, dans
`tablesTirees` (`lib/core/sync/pull_registry.dart`) — requête distante et
mapping vers Drift côte à côte. C'est l'écart entre les deux qui produisait le
bug : ils vivaient à trois cents lignes de distance. Tout mapping base →
entité doit par ailleurs être complet.

**Gardes automatiques** : `test/sync_pull_coverage_test.dart` construit, pour
chaque table du registre, une ligne distante portant **toutes** ses colonnes et
vérifie qu'aucune ne ressort nulle — il nomme la colonne fautive. Avec
`test/product_entity_mapping_test.dart` pour le mapping base → entité.

---

## 2. Le serveur écrase une écriture locale non partie

**Symptôme** : le stock « remonte » après une vente, un module désactivé se
réactive tout seul.

La garde vit **dans** la fonction de téléchargement, jamais chez l'appelant :
des écrans appellent le pull directement et la contourneraient.
`shop_settings_provider` avait son propre téléchargement sans garde — le
serveur renvoyait l'ancien réglage encore en file.

**Garde automatique** : `test/sync_pull_guard_test.dart`.

---

## 3. Une table absente casse tout le téléchargement

**Symptôme** : plus aucune donnée ne descend, pour une seule table manquante
(migration non appliquée, version publiée en avance).

Chaque table est désormais tirée indépendamment, et les échecs sont tracés
`[SYNC]` dans les logs. Sans ces traces, l'échec devient silencieux : l'app
affiche des données manquantes sans dire pourquoi.

---

## 3bis. Une opération refusée gèle toute la file, en silence

**Symptôme** : le compteur d'opérations en attente ne descend plus, le
téléchargement ne se fait plus, et rien ne le dit. Vu en vrai : un transfert
refusé par `apply_stock_movement` (« Stock insuffisant ») a bloqué l'envoi de
tout ce qui a été saisi ensuite.

La file reste ordonnée — un produit doit être créé avant qu'on lui ajoute du
stock — mais l'ordre ne vaut qu'**entre opérations liées**. `_porteesDe()`
décrit ce que chaque opération touche : deux portées disjointes ne s'attendent
pas. Après `maxRefusAvantMiseDeCote` refus, l'opération passe **de côté** :
gardée, plus renvoyée seule, et signalée par un bandeau rouge qui mène à
l'écran de synchro pour réessayer ou abandonner.

Trois réflexes :

- **Un réseau coupé n'est pas un refus.** `estUnRefusDuServeur()` fait la
  différence : sans elle, une semaine hors couverture mettrait de côté tout le
  travail d'un commerçant.
- **Une charge illisible arrête tout.** On ne sait pas ce qu'elle touche, donc
  on ne peut pas laisser passer la suite.
- **Le téléchargement reste bloqué tant qu'une opération est de côté.** C'est
  volontaire : le débloquer écraserait le stock local avec un stock serveur qui
  ignore l'opération refusée. Mieux vaut un arrêt visible qu'un chiffre faux.

**Gardes automatiques** : `test/sync_queue_quarantine_test.dart`,
`test/sync_queue_order_test.dart`.

---

## 4. Comparer des dates au jour ou à l'instant — choisir exprès

| Ce qu'on compare | Granularité | Pourquoi |
|------------------|-------------|----------|
| Recettes et pertes dans la période | **jour** | le commerçant déclare « le 14 », pas « à 12h07 » |
| Coût du stock d'ouverture | **instant** | une hausse saisie 6 min après l'ouverture ne doit pas revaloriser le stock déjà en rayon |
| Tarifs du même jour | tri à **l'heure** | sinon le prix retenu dépend de l'ordre des lignes en base |

Bugs réels : pertes notées après le comptage → rapport inchangé sans un mot ;
12 sacs de riz à 22 000 revalorisés à 24 000 ; une date choisie au calendrier
vaut minuit, donc antérieure au comptage du matin, donc exclue.

---

## 5. Le prix d'aujourd'hui réécrit le passé

Un montant valorisé au prix **actuel** du produit fait bouger toutes les
périodes déjà closes. Le prix d'achat vit sur `stock_purchases`, le prix de
vente sur `product_prices`, chacun avec sa date.

**Reste ouvert** : `stock_movements` est poussée **sans date** — le serveur
pose la sienne. Deux téléphones mal réglés, ou un téléphone dont on recule la
date pour un test, verront des recharges à des dates différentes.

---

## 6. Bloquer une saisie qui est une information

Compter plus que le stock possible **n'est pas une erreur** : c'est un
arrivage non enregistré. Bloquer ferait taper un chiffre faux pour passer
l'écran, et l'information disparaîtrait. Un **comptage est une observation**,
on ne discute pas avec elle — on avertit après coup.

Une **perte est une déclaration**, pas une observation : elle a un plafond
connu, on peut la refuser.

---

## 7. L'écran ment sur ce qu'il fait

- L'unité était à retaper à chaque produit → doublons `carton` / `Carton`.
- Une unité nommée « 30 » avec un ratio 360 → −16 000 F. **Le formulaire était
  en cause, pas l'utilisateur** : pas de récapitulatif de conversion.
- Une confirmation transitoire qui répète un état déjà affiché est du bruit
  (15 bandeaux sur un tour de comptage).
- Un écart affiché sans un mot se lit « on m'a volé ».
- `sharePdf` envoyait le fichier sans jamais le montrer ; le bilan utilise
  `layoutPdf`, qui affiche le document.

---

## 8. Débordements sur petit écran

Trois occurrences. Toute liste sous un bouton flottant réserve ~96 px en bas ;
tout formulaire est scrollable (le clavier prend la moitié de la hauteur) ;
un bloc de synthèse en PDF est `pw.Inseparable`, sinon il se coupe entre deux
pages — mais il doit alors **tenir** sur une page, sinon il part en page 2 en
laissant un blanc.

---

## 9. Un avertissement d'analyse peut cacher un module débranché

`flutter analyze` signalait deux variables inutilisées :

```
warning • The value of the local variable 'transfersIn' isn't used
warning • The value of the local variable 'transfersOut' isn't used
```

Le calcul des transferts était bien écrit, mais le rapport recevait toujours
`transfersIn: 0, transfersOut: 0` — un remplacement de texte qui n'avait pas
trouvé son motif, sans que rien n'échoue. **Tout B8 était décoratif** : le
stock bougeait, et le rapport annonçait un manquant inexpliqué de la quantité
transférée.

Ne jamais balayer un avertissement « variable inutilisée » comme du bruit :
une valeur calculée que personne ne lit veut dire qu'un branchement manque.

## 10. Un `ref` de widget meurt pendant un `await`

`Bad state: Cannot use "ref" after the widget was disposed.`

Vu sur le sélecteur de boutique : changer de boutique reconstruit la barre de
titre, donc détruit le menu **au milieu de sa propre méthode**. Les
invalidations qui suivaient ne partaient jamais — on aurait changé de boutique
en gardant les écrans de l'ancienne.

Dans toute méthode d'écran qui `await` puis touche à des providers, capturer
`ProviderScope.containerOf(context, listen: false)` **avant** le premier
`await` et travailler avec lui : il survit au widget qui l'a appelé.

## 11. Outillage

- **Installer le build `--debug --target-platform android-arm`.** Un APK
  release n'est pas *debuggable* → plus de lecture de la base SQLite, l'outil
  qui a trouvé tous les bugs ci-dessus. Le téléphone de test est armeabi-v7a :
  un APK arm64 s'installe puis **crashe au lancement**.
- `flutter run` reste attaché et peut réinstaller en arrière-plan sans qu'on
  le voie — un processus oublié a effacé les données de test en pleine session.
- Le téléchargement **fusionne, il ne supprime jamais** : une ligne effacée sur
  Supabase reste sur le téléphone. Pour repartir à zéro, vider les deux.
