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

---

## 12. « La » boutique du compte — une question sans réponse

**Symptôme** : `PostgrestException PGRST116 — Cannot coerce the result to a
single JSON object. The result contains 3 rows.` Ou, plus discret : une vente
qui atterrit dans la mauvaise épicerie.

Trois endroits demandaient encore au serveur la boutique d'un compte via un
`.single()` sur `shop_members` — une question qui n'a de réponse que si le
commerçant n'a qu'une boutique. Le client type en a trois.

| Endroit | Ce que ça donnait |
|---------|-------------------|
| Création de produit | plantage sec dès la 2ᵉ boutique |
| Modification de produit | retombait sur la boutique du 1ᵉʳ produit de la liste — juste par coïncidence, cassé sur liste vide |
| Vente | même appel voué à l'échec, rattrapé par un `catch` silencieux : marchait **par accident** |

**Règle** : la boutique active se lit **toujours** avec `requireShopId(ref)`
(action) ou `watchShopId(ref)` (build). Jamais une requête réseau, qui ne sait
de toute façon pas laquelle est ouverte à l'écran.

Le plus instructif est le troisième : un repli silencieux qui rattrape une
requête toujours fautive finit par masquer le jour où il se trompe de boutique.

---

## 13. `read` au lieu de `watch` sur la boutique active

**Symptôme** : l'écran Stock affiche « 0 produit » pendant que le comptage en
liste cinq. Une déconnexion/reconnexion « répare » tout.

`productProvider` lisait la boutique avec `ref.read` : il ne se reconstruisait
donc **jamais** quand elle changeait. Créée juste avant, la boutique n'était pas
encore connue au moment du build — il concluait « aucun produit » et ne reposait
plus jamais la question.

`current_shop_provider.dart` **documente ce piège dans son propre commentaire**,
avec deux cas déjà rencontrés. C'était le troisième.

**Règle** : dans un `build` de provider, la boutique active se `watch`. Le
`read` est réservé aux actions, où `watch` est de toute façon interdit.

---

## 14. Ce que le destinataire ne peut pas aller chercher

**Symptôme** : « Produit inconnu », « Autre boutique », ou une réception qui
**ne fait rien du tout, sans un mot**.

`stock_transfers` ne portait que des identifiants : `product_id` désigne la
fiche de la boutique **expéditrice**, `from_shop_id` une boutique dont le
destinataire n'est pas membre. Or :

- le pull filtre par boutique active → la fiche produit de l'expéditeur n'est
  jamais téléchargée chez le destinataire ;
- les RLS interdisent à un vendeur de lire une boutique dont il n'est pas
  membre — **à raison**.

Chez le patron, membre de tout, les noms se résolvaient : le bug était
invisible. Il n'apparaît que côté vendeur, ou sur un second appareil.

**Règle** : une ligne qui traverse une frontière de permission emporte ce
qu'il faut pour être lue de l'autre côté. `sale_items` le fait depuis toujours
avec `product_name`, `buy_price`, `sell_price`. `stock_transfers` porte
désormais `product_name`, `buy_price`, `sell_price`, `unit`, `from_shop_name`,
`to_shop_name` — figés à l'envoi, ce qui est aussi plus juste : renommer une
boutique ne doit pas réécrire l'historique.

**Corollaire** : comparer des noms de produits **en ignorant la casse et les
espaces**. « pain » et « Pain » sur deux boutiques tenues par la même personne
est le cas normal, pas l'exception — la comparaison exacte créait deux fiches
du même article.

---

## 15. Le ménage de session n'a qu'un seul propriétaire

**Symptôme** : un commerçant crée un second compte sur le même téléphone et se
retrouve **vendeur sur sa propre boutique**, avec les produits de l'autre compte
en base. Ou : un appareil neuf ouvre une boutique vide alors que le stock est
sur le serveur.

Trois défauts empilés, tous dans le même geste :

| Défaut | Conséquence |
|--------|-------------|
| L'inscription ne faisait **aucun** des ménages que faisait la connexion | boutique active et données locales du compte précédent conservées |
| `cached_user_id` n'était écrit que par le tableau de bord | jamais en mode inventaire (autre accueil) → changement de compte jamais détecté |
| Le rechargement ne se déclenchait qu'au **changement** de compte | un appareil neuf n'a pas de compte précédent → aucun téléchargement, jamais |

**Règle** : tout ce qui suit une authentification vit dans
`prendreEnMainLaSession()` — un seul endroit, appelé par la connexion **et**
l'inscription. Deux chemins qui font « presque » la même chose divergent
toujours.

---

## 16. Un `await` réseau ne doit pas faire mentir une écriture locale

**Symptôme** : le commerçant saisit son fonds de caisse, l'écran passe en
erreur, il recommence. Quatre fonds de caisse enregistrés pour une journée.

`saveMorningBalance`, `closeDay` et `reopenDay` écrivaient en local puis
laissaient l'échec de l'envoi remonter jusqu'à l'écran — alors que la saisie
avait bel et bien réussi. Sur la clôture, le même défaut aurait produit deux
clôtures pour un même jour, la seconde refusée par le serveur.

**Règle** : local-first veut dire que l'écran se rafraîchit **avant** l'envoi.
Le réseau part ensuite, en tâche de fond, et ne peut plus faire paraître ratée
une écriture déjà en base.

**Corollaire d'interface** : un bouton qui ne fait rien quand la saisie est
invalide est pire qu'une erreur. Le commerçant ne peut pas distinguer
« enregistré » de « ignoré ».

---

## 17. Ce que l'app sait mais ne dit pas

Une famille entière de défauts trouvés en une campagne : l'app calcule juste,
et se tait au moment où il faudrait parler.

| Cas | Ce que le commerçant voyait |
|-----|------------------------------|
| Recettes notées avant le tout premier comptage | « 0 F » — 443 250 F évaporés sans un mot |
| Quantité vendue et nombre de pertes d'un cycle | calculés, gardés en variable locale, jamais affichés |
| Transfert envoyé, pas encore reçu | ligne identique à un transfert terminé |
| Unité de base manquante | vente au détail impossible, sans explication |
| Deuxième cycle ouvert sur un produit | les ventes basculaient dessus **en silence** |
| Date de comptage choisie puis écrasée | trois périodes identiques, incompréhensibles |

**Règle** : quand un calcul écarte une donnée, le dire. Un bandeau
d'explication — bleu, pas rouge, quand c'est une explication et non une
anomalie — vaut mieux qu'un zéro que personne ne sait interpréter.

---

## 18. Ce que seuls deux appareils révèlent

Une journée entière de tests sur un seul téléphone n'avait rien montré des
défauts n° 14, 15 et 13. Trente minutes avec un émulateur à côté les ont tous
sortis.

La raison est mécanique : **un seul appareil accumule**. Sa base locale finit
par contenir les produits de toutes les boutiques ouvertes, son
`cached_user_id` est toujours renseigné, tous les noms se résolvent. Il ne
ressemble à aucun appareil de client.

**Règle** : avant toute livraison, rejouer sur un **second appareil vierge** —
`emulator -avd Pixel_5` suffit — au minimum : première connexion d'un compte
jamais vu, parcours vendeur, et un transfert reçu depuis une boutique que cet
appareil n'a jamais ouverte.

---

## 19. Les tests automatiques ne voient pas ces bugs-là

**117 tests au vert du début à la fin** de la campagne des 18-19/08/2026, qui a
pourtant trouvé vingt-six défauts. Aucun n'a été détecté par la suite de tests.

Ce n'est pas un défaut de la suite, c'est sa nature : elle vérifie des
**calculs purs** — bénéfice d'un cycle, écart d'un inventaire, quelle route
s'ouvre à qui — sans téléphone, sans réseau, sans Supabase. Elle ne peut pas
voir un `.single()` qui casse à la deuxième boutique, un `read` au lieu d'un
`watch`, une synchro qui ne se déclenche jamais, ou une casse de nom qui
duplique une fiche. Tout ce qui a été trouvé est de l'**intégration**.

**Ce que la suite apporte quand même** : chaque bug de calcul corrigé y est
verrouillé. Le recasser en touchant un fichier voisin se voit en trente
secondes, sans téléphone.

**Ce qu'elle ne remplacera jamais** : quelqu'un qui utilise l'application comme
un commerçant, pas comme un développeur. Les tests vérifient ce qu'on a pensé à
vérifier ; le test manuel tombe sur ce qu'on n'avait pas prévu. Les deux, pas
l'un ou l'autre.

---

## 20. Le téléchargement réussit derrière un écran resté vide

**Symptômes, apparemment sans rapport** — « je dois fermer l'application et la
rouvrir pour que les produits s'affichent dans le comptage » ; « le vendeur se
connecte sur l'émulateur, aucun produit, alors que la Samsung en a sept ».

**Cause unique** : `pullDataFromSupabase()` remplit Drift et ne prévient
personne. Un provider dont le `Future` est déjà résolu garde son résultat — sur
un téléphone neuf, ce résultat est vide, et rien ne le recalcule jamais. Les
logs le datent à la seconde : connexion à 14:03:14, `[SYNC] téléchargement
terminé — 7 produits` à 14:03:51. Trente-sept secondes d'écran vide, puis un
vide définitif.

**Ce qui l'a trahi** : la ligne `[SYNC] téléchargement terminé` dans `adb
logcat` annonçait les 7 produits pendant que l'écran en affichait zéro. Sans
cette trace, le diagnostic partait vers RLS ou le rattachement du vendeur — les
deux étaient corrects.

**Correction** : `revisionDonneesLocalesProvider`
(`lib/core/sync/revision_donnees.dart`), incrémenté après la transaction du
pull et surveillé par `watchShopId()` — le passage commun à toute lecture liée
à une boutique. Les quelques providers qui ne passent pas par lui
(`productProvider`, `cyclesProvider`, `cycleReportProvider`, `dashboardProvider`)
le surveillent directement.

**Règle** : une écriture en base faite **hors** d'une action d'écran doit
incrémenter ce compteur. Écrire dans Drift ne rafraîchit rien tout seul.

**Pourquoi ça ne clignote pas** : la synchro n'est jamais déclenchée par un
minuteur, seulement par un événement — reprise de l'app, retour du réseau,
connexion, changement de boutique, tirer pour rafraîchir.

**Le contrecoup, trouvé une heure plus tard** : `dashboardProvider` déclenche
lui-même un téléchargement à chaque construction (`_runBackgroundSync`). Lui
faire surveiller le compteur a bouclé — synchro → compteur → reconstruction →
synchro, **un tour toutes les 700 ms**, visible dans `logcat` comme une
répétition de `[SHOPS] réponse brute` / `[SYNC] téléchargement terminé`. Deux
produits sur huit ont pu être créés avant que l'app devienne inutilisable.

**Règle** : un provider qui **déclenche** une synchro ne doit pas **surveiller**
ce compteur. Et par sécurité, `pullDataFromSupabase()` ne l'incrémente que si
l'empreinte du contenu téléchargé a changé — une boucle éventuelle fait un tour
au lieu de tourner sans fin, et une reprise d'app sans nouveauté ne reconstruit
plus toute l'interface.

---

## 21. Deux écrans qui comptent juste et se contredisent

**Vu en vrai** : l'accueil annonce « 3 jours sans recette notée », le rapport de
la même période « 6 jour(s) ». Les deux calculs étaient corrects.

L'accueil part de la **première recette notée** et s'arrête **avant
aujourd'hui**. Le rapport partait du **premier comptage** et allait **jusqu'à
aujourd'hui inclus**. Un seul des trois écarts était un bug — le jour même, où
la recette se note le soir venu.

**Ce qui restait après correction** : les jours entre le premier comptage et la
première recette, absents de l'accueil et légitimes dans le rapport. Deux
définitions différentes pour deux questions différentes.

**Règle** : quand deux écrans affichent le même intitulé avec deux nombres, ne
pas forcer l'un à copier l'autre — **montrer les éléments comptés**. Le rapport
liste désormais les dates, comme l'accueil : la différence s'explique d'elle-même
et n'a plus besoin d'être expliquée.

---

## 22. Une heure locale envoyée sans son fuseau

**Vu en vrai le 21/08/2026** : le téléphone affiche 12:37, le journal de caisse
date les ventes de 13:36 et 13:28. Une heure d'avance, exactement le décalage
du Cameroun (UTC+1).

**Cause** : `DateTime.now().toIso8601String()` sur une date **locale** produit
`2026-08-21T12:36:00.000` — sans suffixe de fuseau. Postgres la range dans une
colonne `timestamptz` en la supposant universelle, puis
`DateTime.parse(...).toLocal()` à la relecture y rajoute l'heure du pays.

**Douze endroits étaient concernés**, en deux familles :
- six **écritures** (`created_at` d'une vente, d'un mouvement de caisse, d'une
  perte de cycle ; `opened_at`/`closed_at` d'un cycle) — instant faux ;
- six **bornes de requête** (`startOfDay`, `endOfDay`, `startDate`, `endDate`)
  — fenêtre décalée d'une heure.

**Plus grave que cosmétique** : une vente faite après 23h locale était rangée
au lendemain. Elle disparaissait de la journée en cours, donc de sa clôture de
caisse, et réapparaissait dans celle du lendemain. L'écart de caisse du soir
devenait inexplicable.

**Règle** : toute date envoyée à Supabase passe par `.toUtc()`. Sans exception,
bornes de requête comprises. Le contrôle tient en une commande :

```bash
grep -rn "toIso8601String()" lib/ --include=*.dart | grep -v "toUtc()"
```

Elle doit ne rien renvoyer.

**Les données déjà écrites gardent leur décalage** : elles ont été enregistrées
avec la mauvaise valeur, la corriger demanderait de savoir quelles lignes sont
antérieures au correctif. Sans conséquence sur les montants — seule l'heure
affichée est décalée, et la date ne change que pour les ventes de fin de
soirée.

---

## 23. Une lecture locale qui oublie la boutique

**Vu en vrai le 21/08/2026** : passer d'une boutique en vente simple à une
ferme en mode cycles sur le même téléphone affichait les cycles — et le bilan —
de la boutique précédente. Un tirer-pour-actualiser corrigeait l'affichage, ce
qui rendait le défaut intermittent, donc difficile à croire.

**Cause** : le pull **fusionne** sans jamais vider (voir `sync_service`). La
base locale garde donc les données de chaque boutique visitée sur cet appareil.
Toute lecture Drift qui ne filtre pas par `shopId` les mélange.

**Deux foyers trouvés** :
- `cyclesProvider` lisait `localSupplyCycles` **sans aucun filtre** et sans
  surveiller la boutique active : ni cloisonné, ni rafraîchi ;
- `dashboard_provider` avait **douze** lectures — clôtures, ventes, mouvements
  de caisse — filtrées par date seulement. Une journée close ailleurs masquait
  celle qui restait à faire ; les ventes d'une épicerie réclamaient la clôture
  d'une autre.

**Règle** : toute lecture d'une table locale porteuse d'un `shopId` filtre
dessus, et l'obtient par `watchShopId(ref)` — jamais par `read` — pour que
changer de boutique reconstruise l'écran. Le contrôle :

```bash
grep -rn "db.select(db.local" -A 4 lib/ --include=*.dart | grep -B 2 "where"
```

Chaque bloc doit contenir un `shopId.equals`. Deux exceptions légitimes, toutes
deux commentées : la recherche du produit d'origine d'un transfert, qui vit par
construction dans une AUTRE boutique.

**Pourquoi les tests ne le voyaient pas** : ils créent une seule boutique. Il
faut deux boutiques sur le même appareil, donc deux jeux de données mêlés dans
la même base locale — exactement ce que produit une journée d'essais réels.

---

## 24. Un écran oublié dans la liste des invalidations

**Vu en vrai le 24/08/2026** : le commerçant valide son tour de comptage, ouvre
« Mes comptages », et n'y voit rien. Ses repères n'apparaissent qu'après avoir
vidé les données de l'application — de quoi croire que le travail n'a pas été
enregistré.

**Cause** : `saveCount` invalidait `inventoryCountProvider`, `productProvider`
et `inventoryReportProvider`, mais pas `historiqueComptagesProvider`. Ce
dernier a été ajouté après les trois autres, et personne n'a pensé à
l'inscrire dans la liste.

C'est le pendant du piège n°20 : là, le téléchargement remplissait la base sans
réveiller les écrans ; ici, c'est une action locale qui réveille trois écrans
sur quatre. Même symptôme pour le commerçant — « mon travail a disparu ».

**Règle** : quand on ajoute un provider qui lit une table déjà écrite par une
action existante, chercher cette action et l'y inscrire. Le contrôle, pour les
providers d'inventaire :

```bash
grep -n "ref.invalidate" lib/features/inventory/presentation/providers/*.dart
```

Chaque action doit réveiller TOUS les écrans qui lisent ce qu'elle écrit.

---

## 25. Un total partiel comparé à une caisse entière

**Symptôme** : le rapport d'inventaire annonce un bénéfice — ou un excédent —
qui n'existe pas. Sur une boutique à 100 000 F par jour dont la moitié des
produits vient d'être recomptée, l'app affichait **1 500 000 F d'excédent**
inventé, en gros et en vert, avec la réserve écrite en petit dessous.

**Cause** : chaque produit calcule ses sorties sur **sa propre fenêtre** (de
son comptage précédent au sien), mais les recettes étaient additionnées sur
**une seule grande enveloppe** allant du plus ancien repère au plus récent, et
la recette d'une boutique est un montant unique pour **tous** ses produits. On
comparait donc les sorties de dix articles à l'argent encaissé sur vingt.

Le même défaut existe en plus petit quand les produits sont comptés par vagues
étalées : chaque jour d'écart entre la première et la dernière vague apporte de
l'argent sans apporter de sorties.

**Règle** : `verdictFinancierFiable` garde tout ce qui compare le calculé à
l'encaissé — bénéfice, écart, et les mêmes sections du PDF. Il exige deux
choses, et il faut les deux :

- **tout est compté** (`isComplete`) ;
- **aucune recette n'est oubliée** (`daysWithoutTakings` vide) — un jour non
  noté produit exactement le même chiffre qu'un vol du même montant, et
  quelqu'un se fait accuser sur un oubli de saisie.

Quand c'est faux, l'écran montre ce qui est **sorti** produit par produit — un
fait vérifiable — et ce qu'il reste à faire. Jamais un montant assorti d'une
réserve : le commerçant retient le montant et oublie la réserve.

Vérifié par `test/inventory_bilan_partiel_test.dart`.

---

## 26. Un article rangé qui gèle toute la boutique

**Symptôme** : le bandeau « résultat partiel » ne part plus, quoi que le
commerçant compte. Et, dans le cas grave, plus aucune nouvelle période ne
s'ouvre — jamais.

**Cause** : l'écran de comptage exclut les produits archivés
(`archivedAt.isNull()`), mais le rapport les gardait dans **tous** ses calculs.
Un archivé n'étant plus jamais recomptable, il restait éternellement « en
attente d'un 2e comptage » : `isComplete` ne pouvait plus redevenir vrai. Pire,
un archivé possédant deux comptages retenait le nombre de comptages commun, et
bloquait définitivement l'ouverture de la période suivante.

Constaté sur des données réelles : sept articles rangés dans une seule boutique
suffisaient.

**Règle** : la distinction n'est pas « on filtre » ou « on ne filtre pas », elle
est en deux temps :

- un archivé **ne borne plus rien** — hors du calcul des périodes disponibles,
  hors de `produitsAFinirDeCompter`, hors des compteurs « jamais compté » et
  « en attente » ;
- un archivé **reste dans les périodes où il a servi** — s'il a ses deux
  repères pour la période affichée, ses sorties y sont, parce qu'un bilan déjà
  consulté ne se réécrit pas.

Le filtrer partout aurait effacé ses lignes d'un rapport déjà imprimé, ce que
`CLAUDE.md` interdit explicitement.

---

## 27. « Il en reste 10 » sans dire lesquels

**Symptôme** : le commerçant recompte une partie de sa boutique, revient au
rapport, lit « 10 en attente d'un 2e comptage » — et n'a aucun moyen de savoir
lesquels. Il repart parcourir ses rayons.

**Cause** : la liste des produits à finir ne regardait que ceux ayant **déjà
deux repères**, et ne les nommait que si l'un d'eux avait pris de l'avance.
Juste après un premier tour complet, personne n'est en retard sur personne : la
liste sortait vide alors qu'il restait tout le catalogue à recompter.

**Règle** : le seuil à atteindre est le **maximum** de comptages observé parmi
les produits actifs, et jamais moins de deux. Tout produit en dessous est à
compter, y compris ceux qui n'ont qu'un repère ou aucun.

```dart
final seuil = math.max(2, comptagesParId.values.reduce(math.max));
```

Vérifié sur les quatre étapes du scénario à 20 produits : les 20 après le
premier tour, les 10 oubliés quand la moitié est recomptée, aucun quand tout
est à égalité, les 15 en retard quand 5 ont pris de l'avance.

---

## 28. Le jour de bascule réclamé des deux côtés

**Symptôme** : à partir de la **deuxième** période, le rapport signale toujours
un jour sans recette — celui de son ouverture — et le bilan reste bloqué. Noter
la recette de ce jour ne change rien : elle reste signalée manquante.

**Cause** : deux boucles lisent les mêmes jours avec deux règles différentes.

La boucle des **recettes** applique correctement la règle du jour de bascule :
le jour d'ouverture appartient à la période qui se **ferme**, sauf s'il n'y a
rien avant lui (`ouvertureIncluse`). Sa recette est donc exclue du total, et
elle n'entre jamais dans `notedDays`.

La boucle des **jours manquants**, elle, partait de `from` sans condition. Elle
cherchait donc ce jour dans `notedDays` — où il ne pouvait pas être. Boucle
fermée : le jour manquait pour toujours.

**Ce qui l'a rendu grave** : tant que `daysWithoutTakings` n'était qu'un
bandeau d'information, le défaut passait pour un détail cosmétique. Depuis que
`verdictFinancierFiable` s'appuie dessus (piège n°25), il bloquait le bénéfice
de **toutes** les périodes suivantes, définitivement. Un correctif juste a
transformé un détail en mur.

**Règle** : deux boucles qui parcourent la même fenêtre doivent partager la
même borne. Ici :

```dart
final premierJourAVerifier = ouvertureIncluse
    ? from
    : from.add(const Duration(days: 1));
```

**Ce qui l'a trahi** : un test manuel sur une deuxième période. Les 136 tests
automatiques ne l'ont pas vu — ils ne construisaient jamais deux périodes
successives avec des recettes complètes. Vérifié désormais par
`test/inventory_bilan_partiel_test.dart`.

---

## 29. Avancer la date de l'appareil casse toutes les requêtes serveur

**Symptôme** : un écran tourne en rond indéfiniment, sans message d'erreur.
Vu le 27/08/2026 sur « Employés », mais n'importe quel écran qui interroge le
serveur fait pareil.

**Cause** : l'émulateur avait été avancé de trois jours pour tester les
périodes d'inventaire. Les jetons d'authentification portent alors une date
d'émission **dans le futur** par rapport au serveur, et PostgREST les refuse :

```
PostgrestException: JWT issued at future — code PGRST303, Unauthorized
```

Le piège est que **la connexion elle-même continue de fonctionner** :
`supabase.auth` rafraîchit sa session sans se plaindre, l'app se croit
connectée, la boutique et le rôle s'affichent — et seules les requêtes de
données échouent. Rien à l'écran ne dit « le serveur me refuse ».

**Règle** : après avoir décalé la date d'un appareil pour tester, la remettre
à l'automatique **et redémarrer l'application** — le jeton en mémoire porte
encore l'ancienne date et le premier téléchargement échoue même après la
remise à l'heure.

```bash
adb shell settings put global auto_time 1
adb shell am force-stop cm.shoptrack.shoptrack
```

**Le décalage inverse est sans danger** : un jeton émis dans le passé reste
valide jusqu'à son expiration. Seul l'avance pose problème.

**Ce qui l'a trahi** : `adb logcat | grep flutter` — l'échec est écrit en
clair par `[SYNC]`, alors que l'écran ne montre qu'un cercle qui tourne. Un
écran qui tourne sans fin après un test de dates : chercher PGRST303 avant
toute chose.

---

## 30. Un type ajouté côté Dart que le serveur ne connaît pas

**Symptôme** : bandeau rouge « Synchronisation incomplète — 1 opération refusée
par le serveur », avec un message technique illisible pour un commerçant :

```
new row for relation "cash_movements" violates check constraint
"cash_movements_type_check", code: 23514
```

**Cause** : la caisse continue enregistre un `adjustment_in` ou
`adjustment_out` chaque fois que le montant réellement compté diffère du
calcul. Le code Dart les produisait, la contrainte `CHECK` de la table ne
connaissait que `morning_balance`, `withdrawal` et `incoming`. Chaque
ajustement partait, se faisait refuser cinq fois, puis était mis de côté.

**Ce qui rend le cas instructif** : tout a fonctionné comme prévu. La file a
retenu l'opération, le compteur de refus l'a mise en quarantaine, le bandeau
l'a signalée, rien n'a été perdu ni écrit de travers. Le seul défaut est que le
commerçant voit une erreur qu'il ne peut ni comprendre ni résoudre.

**Règle** : un type, un statut ou une catégorie ajoutés côté Dart **n'existent
pas** tant que la contrainte du serveur ne les connaît pas. Les deux
vocabulaires bougent dans la même livraison.

Le contrôle avant de livrer un nouveau type :

```sql
select conname, pg_get_constraintdef(oid)
from pg_constraint
where conrelid = 'public.<table>'::regclass and contype = 'c';
```

**Familles concernées** : `cash_movements.type`, `inventory_losses.reason`,
`dossiers_commandes.statut` et `categorie`, `paiements_commandes.mode_paiement`
et `type_mouvement`. Toutes portent une liste fermée côté serveur.

**Ce qui l'a trahi** : l'écran « État de synchronisation ». Sans lui, l'opération
serait restée invisible — le solde local aurait été juste, le serveur l'aurait
ignoré, et l'écart ne serait apparu que sur un second téléphone.

---

## 31. L'erreur affichée n'est pas celle qui bloque

**Symptôme** : « Synchronisation incomplète » avec un message qui désigne une
opération parfaitement valide.

```
insert or update on table "sale_items" violates foreign key constraint
"sale_items_product_id_fkey" — Key is not present in table "products"
```

La vente n'avait rien de faux. Son produit existait bien, en local. Le vrai
problème était **trois opérations plus tôt** : un mouvement d'ajustement dont
le type était refusé par la contrainte du serveur (piège n°30).

**L'enchaînement** :

1. l'ajustement est refusé cinq fois, il passe en quarantaine ;
2. une opération mise de côté **retient celles de même portée** — c'est
   voulu, sinon une vente partirait sans le produit qu'elle référence ;
3. la création du 5ᵉ produit attend derrière ;
4. les ventes qui pointent vers ce produit échouent sur une clé étrangère ;
5. l'écran affiche **la dernière erreur**, donc la conséquence.

Corriger la contrainte a suffi : l'ajustement est passé, puis le produit, puis
les huit ventes et six clôtures d'une semaine de saisie hors ligne. Rien
n'avait été perdu ni écrit à moitié.

**Règle de diagnostic** : devant une file bloquée, lire **la plus ancienne
opération en quarantaine**, jamais le dernier message affiché. Le dernier
décrit un symptôme ; le premier porte la cause.

```sql
-- côté téléphone, la file dans l'ordre où elle partira
select id, action, substr(payload, 1, 120) from sync_queue_items order by id;
```

**Ce qui l'a rendu trompeur** : le message parlait de `products` alors que les
produits allaient parfaitement bien. Chercher du côté des produits aurait pu
coûter une journée.

## 32. De l'argent encaissé qui n'entre jamais dans le tiroir

**Vu le** 31/08/2026, en écrivant le module commandes — avant la première
utilisation, ce qui est la seule bonne nouvelle de l'histoire.

Le module enregistre un acompte : la cliente commande un gâteau à 150 000 F et
verse 40 000 F en espèces. Le dossier est juste, le solde est juste, l'écran
est juste. `paiements_commandes` porte la ligne.

Et le soir, la clôture annonce **40 000 F de surplus**.

Parce que la caisse ne se calcule pas à partir des dossiers. Elle se calcule à
partir de `sales` et de `cash_movements`, et rien d'autre. Un acompte écrit
dans sa propre table est invisible pour elle : les billets sont dans le tiroir,
l'application ne les connaît pas, et l'écart est attribué à la personne qui a
compté.

C'est exactement le défaut du Mobile Money compté comme espèces, dans l'autre
sens — et il se rejoue à chaque module qui touche de l'argent.

**La règle** : *tout ce qui entre ou sort du tiroir physique écrit un
`cash_movement`, quelle que soit la table qui porte le métier.* Une table
métier décrit un engagement ; seule `cash_movements` décrit le tiroir.

Deux détails qui vont avec, et qui se sont vus dans la même heure :

- **Le type**. Un acompte est `incoming`, jamais une vente. Une vente porte une
  marge ; un acompte est de l'argent avancé sur une commande dont on ne connaît
  pas encore le coût. Le passer en vente inventerait un bénéfice.
- **Le remboursement**. Rendre un acompte est un `withdrawal`, donc — par
  défaut — une dépense qui ampute le bénéfice. Mais l'argent rendu n'était
  jamais entré dans le bénéfice : sa catégorie rejoint
  `categoriesSansImpactSurLeBenefice`. Sans ça, rendre 40 000 F affichait
  « bénéfice −40 000 F », le même écran négatif que le versement à la banque
  (piège #25 bis, vu le 29/08).

**Ce qu'il reste à décider, et qui n'est pas un bug** : ces 150 000 F
remplissent la caisse mais n'apparaissent dans aucun bénéfice, parce que
l'application ne connaît pas le coût d'un gâteau. Le module dit ce qui est
encaissé et ce qui est dû — pas ce qui est gagné. À trancher avec la cliente
avant d'inventer un chiffre.

## 33. Un contrôleur libéré sous un champ encore vivant

**Vu le** 31/08/2026, écran rouge plein écran en tapant un acompte.

```
'package:flutter/src/widgets/framework.dart':
Failed assertion: line 6268 pos 12: '_dependents.isEmpty': is not true.
```

Le code fautif avait l'air raisonnable :

```dart
final controleur = TextEditingController();
final montant = await showModalBottomSheet<int>(...);  // la feuille utilise le contrôleur
controleur.dispose();                                   // ← ici
```

`showModalBottomSheet` rend la main **au moment du `pop`**, pas quand la feuille
a disparu. Pendant l'animation de fermeture, le `TextField` est toujours monté
et toujours branché sur ce contrôleur. On le libère sous lui, et Flutter
s'arrête à la désactivation de l'élément.

**La règle** : *le contrôleur appartient au `State` qui l'utilise, et personne
d'autre ne le libère.* C'est ce que fait `showChoiceSheet` depuis toujours —
`_ChoiceSheetBody` crée son contrôleur et le libère dans son `dispose()`.

`lib/shared/widgets/montant_sheet.dart` existe pour que la règle n'ait plus à
être réapprise : demander un montant passe par `showMontantSheet`, qui possède
son champ. Six tests l'entourent, dont un qui ouvre puis ferme la feuille et
laisse l'animation aller au bout.

**La leçon qui dépasse le cas** : ce projet a déjà trois écrans rouges ou gris
au compteur, tous nés d'une feuille modale écrite à la main plutôt que reprise
de celle qui marchait. Devant un besoin d'interface déjà résolu ailleurs dans
l'application, **reprendre la forme existante avant d'en inventer une**. Le
danger n'est pas le code en trop, c'est la discipline de cycle de vie qu'on ne
recopie pas avec.
