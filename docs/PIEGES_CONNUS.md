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
