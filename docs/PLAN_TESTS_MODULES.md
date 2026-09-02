# Plan de tests — Modules clients (2026-08-11)

> Scénarios à valider **avant** toute mise entre les mains d'un client réel.
> Complète `docs/PLAN_MODULES_CLIENTS.md` (avancement) et
> `docs/ARCHITECTURE_MODULES.md` (conception).
>
> Convention : ✅ validé sur téléphone réel · ⬜ jamais testé · ❌ échec constaté.
> Ne pas cocher « validé » sur la seule foi de `flutter test` : les bugs
> trouvés jusqu'ici (stock écrasé au pull, `cycle_id` effacé, débordements
> d'écran) étaient **tous** invisibles en tests unitaires.

## A. Module A — parcours nominal

| # | Scénario | Attendu | État |
|---|----------|---------|------|
| A1 | Créer un produit, définir `plateau = 30` | Relecture « 1 plateau = 30 X » | ✅ |
| A2 | Créer un cycle 360 / 18 000 | Stock passe à 360 | ✅ |
| A3 | Gain espéré 6 000 → prix conseillé | 2 000 F/plateau, bouton « Utiliser » | ✅ |
| A4 | Vendre 2 plateaux à 2 000 | Stock 300, bénéfice +1 000 | ✅ |
| A5 | Déclarer une perte de 12 | Stock −12, rattachée au cycle | ✅ |
| A6 | Rapport de cycle | CA / coût / pertes / restant / net cohérents | ✅ |
| A7 | Terminer un cycle | Résultat figé, stock intact | ✅ |
| A8 | Vendre après fermeture du dernier cycle | Bascule en vente simple, stock intact | ✅ |
| A9 | Rouvrir un cycle après fermeture | Vente possible à nouveau | ⬜ livré 12/08, à tester |

## B. Module A — cas limites et erreurs

| # | Scénario | Attendu | État |
|---|----------|---------|------|
| B1 | Vendre plus que le stock | Le « + » se bloque au stock | ✅ |
| B2 | Perte supérieure au stock | Refus explicite | ✅ |
| B3 | Unité nommée « 30 » (nombre) | Refusé : « un mot, pas un nombre » | ✅ |
| B4 | Ratio 0 ou négatif | Refusé | ✅ |
| B5 | Supprimer une unité **déjà utilisée** | Refus + message | ✅ |
| B6 | Supprimer une unité **jamais utilisée** | Suppression OK | ✅ |
| B7 | Produit sans unité définie | Vente simple dans le même écran | ✅ |
| B8 | Quantité reçue 0 / coût 0 | Pas de division par zéro | ⬜ |
| B9 | Prix de vente 0 (don, casse offerte) | Accepté, perte affichée en rouge | ✅ |
| B10 | Prix inférieur au coût | Accepté, perte annoncée **avant** validation | ✅ |
| B11 | Deux cycles ouverts sur le même produit | Le plus récent est utilisé | ⬜ |
| B12 | Vendre en carton (360) tout le stock | Conversion correcte, stock à 0 | ⬜ |

## C. Hors ligne et synchronisation (priorité haute)

| # | Scénario | Attendu | État |
|---|----------|---------|------|
| C1 | Vente en mode avion | Enregistrée, file +1 | ✅ |
| C2 | Perte en mode avion | Enregistrée, file +1 | ✅ |
| C3 | Création de cycle en mode avion | Enregistrée, stock à jour | ⬜ |
| C4 | Retour du réseau | File → 0, **stock inchangé** | ✅ |
| C5 | Fermer/rouvrir l'app hors ligne | Données toujours là | ✅ |
| C6 | Réseau coupé **pendant** l'envoi | Pas de double décompte du stock | ⬜ |
| C7 | 10+ opérations en attente | Envoyées dans l'ordre | ⬜ |
| C8 | Une opération échoue | Les suivantes restent en file | ⬜ |

**C4 est le test le plus important du projet** : c'est le bug corrigé le
2026-08-10 (le pull écrasait le stock local non encore envoyé).

## D. Multi-téléphone — **validé le 2026-08-12**

| # | Scénario | Attendu | État |
|---|----------|---------|------|
| D1 | Cycle créé sur tel. A → visible sur tel. B | Oui après synchro | ✅ |
| D2 | Unités créées sur A → visibles sur B | Oui | ✅ |
| D3 | Vente sur A puis vente sur B | Stock cohérent des deux côtés | ✅ |
| D4 | Ventes simultanées A et B, **les deux hors ligne** | Les 2 ventes survivent, stock décompté 2× exactement | ✅ |
| D5 | A hors ligne, B en ligne, puis A revient | Aucune perte de données | ✅ |
| D6 | Rapport de cycle identique sur A et B | Mêmes chiffres | ⬜ |

## E. Coexistence avec le mode simple (non-régression)

| # | Scénario | Attendu | État |
|---|----------|---------|------|
| E1 | Boutique en mode simple | Aucun onglet Cycles, vente classique | ⬜ |
| E2 | Vente simple pendant qu'une autre boutique est en mode œufs | Aucun impact | ⬜ |
| E3 | Boutique œufs vendant aussi un produit **sans** cycle | Vente simple dans le même écran | ✅ |
| E4 | Clôture journalière en mode œufs | Ventes cycles comptées normalement | ⬜ |
| E5 | Bilan mensuel en mode œufs | Chiffres cohérents | ⬜ |

**E3 corrigé le 2026-08-11** : le mode ne se décide plus par boutique mais
**par produit**. Un produit avec unités et cycle ouvert se vend au plateau ;
tout autre produit garde la vente ordinaire, dans le même écran et sans
re-sélection. Le module est donc une couche par-dessus le socle simple, pas
un remplacement.

## F. Caisse et clôture

| # | Scénario | Attendu | État |
|---|----------|---------|------|
| F1 | Solde du matin à 0 | Accepté, la boîte ne revient pas | ✅ |
| F2 | Oublier une journée | Bandeau rouge dans Ventes + clôture sur place | ✅ |
| F3 | Oublier plusieurs journées | Traitées dans l'ordre chronologique | ⬜ |
| F4 | Journée sans vente mais avec caisse | Détectée (corrigé le 11/08) | ⬜ |
| F5 | Écart de caisse négatif | Manque affiché clairement | ⬜ |

## G. Sécurité

| # | Scénario | Attendu | État |
|---|----------|---------|------|
| G1 | Mode vendeur (PIN posé) | Onglet Bilan masqué | ⬜ |
| G2 | Vendeur tentant `/bilan` en direct | Redirigé vers Profil | ⬜ |
| G3 | Écrans Cycles en mode vendeur | **À trancher** : accessibles ou non ? | ⬜ |
| G4 | Données d'une autre boutique | Invisibles (RLS) | ⬜ |

**G3 est une décision à prendre** : aujourd'hui l'onglet Cycles est visible
par tous. Or créer un cycle, c'est saisir des coûts d'achat — une information
que le patron ne veut pas forcément montrer à son vendeur. À arbitrer.

## H. Module B — multi-point et inventaire

**Non commencé.** Aucune ligne de code, aucune migration. Les scénarios ne
seront écrits qu'une fois l'architecture (`ARCHITECTURE_MODULES.md` §2)
transformée en implémentation. Ne pas promettre ce module à un client tant
que le module A n'est pas validé sur le terrain.

## Résultat du 2026-08-12 (S24 Ultra + émulateur Pixel 5)

Les deux appareils ont vendu 2 plateaux chacun **simultanément et tous deux
hors ligne**. Au retour du réseau : les deux ventes ont survécu, sont
présentes des deux côtés, files vides, et le stock est passé de 145 à **85**
— décompté exactement deux fois, ni une ni trois. C'est le scénario patron +
vendeur d'une vraie boutique : il fonctionne.

## Reste à faire avant de confier l'app à un client

**Prioritaire — argent et sécurité, jamais vérifiés :**
- **G1/G2** : en mode vendeur (PIN posé), l'onglet Bilan doit rester masqué et
  `/bilan` inaccessible en direct. La construction des onglets a changé le
  11/08 (`main_layout.dart`, liste unique de destinations) : cette protection
  n'a pas été rejouée depuis.
- **E4/E5** : une vente par cycle doit compter normalement dans la clôture
  journalière et dans le bilan mensuel. Ce sont les écrans sur lesquels le
  patron juge son argent ; ils n'ont jamais été relus en mode œufs.

**Ensuite :** A9 (réouverture, livrée le 12/08), B8/B11/B12, C3/C6/C7/C8,
D6, E1/E2, F3–F5.

## Ordre conseillé pour la suite

1. **B (cas limites)** — évite les mauvaises surprises chez le client.
2. **A7–A9** — fermeture de cycle ; il manque encore le signalement
   « cycle épuisé » et la **réouverture** d'un cycle fermé par erreur
   (aujourd'hui irréversible).
3. **F2–F5** — clôtures rattrapées, livrées mais jamais utilisées.
4. **E, G** — non-régression et arbitrage sur la visibilité des coûts d'achat
   pour un vendeur.

## Scénario de bout en bout validé le 2026-08-14

Épicerie de 15 produits, gros et détail mélangés, sur un téléphone réel
(Android 8.1, armeabi-v7a). Le seul test qui prouve quelque chose : chiffres
calculés à l'avance depuis la base du téléphone, puis comparés à l'écran.

| Étape | Contenu |
|-------|---------|
| Comptage de départ | 15 produits |
| Arrivages | riz +8 à 24 000/27 000 (hausse), Maggi +200, sardines +48 |
| Pertes | 2 bidons (casse), 5 sardines (périmé) |
| Recette | 636 000 F |
| Comptage de fin | 15 produits |

**Résultat, exact au franc près :** valeur sortie 643 830 · il manque 7 830 ·
coût 537 000 · pertes 15 250 · **bénéfice 83 750**.

Le chiffre décisif est le **gain du riz : 46 200 F** = 11 × (27 000 − 22 800).
Il ne tombe juste que si trois mécanismes fonctionnent ensemble : prix de
vente au nouveau tarif, coût en moyenne pondérée (12 à 22 000 + 8 à 24 000),
et **stock d'ouverture qui garde son prix d'achat** malgré une hausse
enregistrée le même jour. Ce dernier point était cassé : `buyPriceAt`
comparait au jour et non à l'instant, donc les 12 sacs déjà en rayon
passaient à 24 000. Trouvé par ce scénario, pas par les tests unitaires.

**Ce que le scénario ne couvre pas encore :** période sur plusieurs jours
(donc pondération réelle du prix de vente par les jours), transferts (B8),
multi-boutique (B7), et le retour des pertes/achats/tarifs sur un second
téléphone.

---

## I. Module C — commandes avec acompte (31/08/2026)

Boutique de test : **`A_commande`**, mode simple (elle vend aussi en boutique),
réglage *Commandes avec acompte* activé. Fonds de caisse de départ **20 000 F**.

Quatre clientes, choisies pour couvrir les quatre catégories **et** les quatre
façons dont l'argent peut se comporter :

| Cliente | Commande | Prix | Ce qu'elle teste |
|---|---|---|---|
| Mme Ngo Bikoi | Gâteau mariage 3 étages, 15/09 | 150 000 | acomptes multiples, espèces **et** Mobile Money |
| Sandrine Efoulan | Vase peint sur mesure | *aucun* | la demande sans prix, prise par la vendeuse |
| Rose Manga | Formation savons | 30 000 | payée en une fois, soldée immédiatement |
| Carine Ekoto | Décoration événementielle | 200 000 | acompte puis **remboursement** |

Plus **une vente boutique ordinaire de 12 000 F (marge 3 000 F)**, sans quoi le
bénéfice reste à zéro et on ne verrait pas s'il devient négatif.

### I.1 — Le réglage et l'onglet

| # | Scénario | Attendu | État |
|---|----------|---------|------|
| I1 | Réglage désactivé | Aucun onglet Commandes | ⬜ |
| I2 | Activer le réglage | L'onglet apparaît sans redémarrer | ⬜ |
| I3 | Désactiver, attendre un téléchargement | Reste désactivé — le serveur ne le rallume pas | ⬜ |
| I4 | Réactiver | Les dossiers créés sont toujours là | ⬜ |

> I3 est le piège déjà rencontré sur `shop_settings_provider` : un module
> désactivé qui revient tout seul parce que le pull a lu l'ancien réglage
> encore en file. Il vaut la peine d'attendre les deux minutes.

### I.2 — Enregistrer une demande

| # | Scénario | Attendu | État |
|---|----------|---------|------|
| I5 | Ouvrir l'onglet, aucun dossier | Message d'accueil, pas d'écran vide | ⬜ |
| I6 | Créer sans nom de client | Refusé, message explicite | ⬜ |
| I7 | Créer sans description | Refusé, message explicite | ⬜ |
| I8 | Sandrine, vase, **sans prix** | « Prix à fixer » en orange + bandeau « Une demande attend son prix » | ✅ 31/08 |
| I9 | Mme Ngo Bikoi, gâteau, prix 150 000, date 15/09 | Reste à payer 150 000, « Pour le 15/09 » | ✅ 31/08 |
| I10 | Les 4 catégories s'enregistrent | Libellé correct dans la liste | ⚠️ 3/4 — `decoration_evenementielle` jamais utilisée |

### I.3 — Le prix

| # | Scénario | Attendu | État |
|---|----------|---------|------|
| I11 | Fixer 45 000 sur le vase de Sandrine | Bandeau orange disparu, solde 45 000 | ⬜ |
| I12 | Corriger 45 000 → 50 000 | Solde 50 000 | ⬜ |
| I13 | Après un acompte de 20 000, corriger le prix à 10 000 | **Refusé** : « Au moins 20 000 F » | ⬜ |

### I.4 — Encaisser

| # | Scénario | Attendu | État |
|---|----------|---------|------|
| I14 | Dossier sans prix | **Aucun bouton Encaisser**, message orange à la place | ⬜ |
| I15 | Ngo Bikoi : 40 000 en espèces | Reste 110 000, ligne « + 40 000 · Espèces » | ✅ 31/08 |
| I16 | Ngo Bikoi : 25 000 en Orange Money | Reste 85 000, ligne « + 25 000 · Orange Money » | ⬜ |
| I17 | Tenter 200 000 sur un solde de 85 000 | **Refusé** : « Pas plus de 85 000 F » | ⬜ |
| I18 | Ngo Bikoi : les 85 000 restants en espèces | « SOLDÉE », passe sous **TERMINÉES**, bouton Encaisser disparu | ⬜ |
| I19 | Rose Manga : 30 000 d'un coup | Soldée immédiatement | ⬜ |

### I.5 — La caisse (le test qui compte)

C'est le piège #32. À faire **dans l'ordre**, en notant le solde caisse de
l'accueil à chaque étape.

| # | Geste | Caisse attendue | Bénéfice attendu | État |
|---|-------|-----------------|------------------|------|
| I20 | Départ (fonds 20 000) | 20 000 | 0 | ⬜ |
| I21 | Vente boutique 12 000 (marge 3 000) | 32 000 | 3 000 | ⬜ |
| I22 | Acompte Ngo Bikoi 40 000 **espèces** | **72 000** | **3 000** | ⬜ |
| I23 | Acompte Ngo Bikoi 25 000 **Orange Money** | **72 000** (inchangée) | 3 000 | ⬜ |
| I24 | Solde Ngo Bikoi 85 000 espèces | 157 000 | 3 000 | ⬜ |
| I25 | Rose Manga 30 000 espèces | 187 000 | 3 000 | ⬜ |
| I26 | Acompte Carine Ekoto 50 000 espèces | 237 000 | 3 000 | ⬜ |
| I27 | **Remboursement Carine 50 000** | 187 000 | **3 000** | ⬜ |
| I28 | Clôturer en comptant 187 000 | **Aucun écart** | 3 000 | ⬜ |

Les deux lignes à ne pas rater :

- **I23** — le Mobile Money ne touche pas le tiroir. S'il le touchait, la
  clôture accuserait quelqu'un de 25 000 F manquants.
- **I27** — le bénéfice reste **3 000 F**, pas **−47 000 F**. L'acompte n'était
  jamais entré dans le bénéfice ; le rendre ne doit pas le creuser. C'est la
  même erreur que le versement à la banque du 29/08.

### I.6 — Rembourser

| # | Scénario | Attendu | État |
|---|----------|---------|------|
| I29 | Rembourser 50 000 à Carine | Ligne « − 50 000 » dans l'historique, **acompte pas effacé** | ⬜ |
| I30 | Tenter de rembourser 80 000 sur 50 000 encaissés | **Refusé** : « Pas plus de 50 000 F » | ⬜ |
| I31 | Le solde de Carine remonte à 200 000 | Le dossier redevient « à encaisser » | ⬜ |

### I.7 — La vendeuse

Passer en mode vendeur (quitter le mode Patron), même boutique.

| # | Scénario | Attendu | État |
|---|----------|---------|------|
| I32 | L'onglet Commandes | Visible — c'est elle qui reçoit le client | ⬜ |
| I33 | Créer une demande | Possible, **sans champ Prix** | ⬜ |
| I34 | Encaisser un acompte | Possible | ⬜ |
| I35 | Bouton « Fixer le prix » | **Absent** | ⬜ |
| I36 | Bouton « Rembourser » | **Absent** | ⬜ |
| I37 | Bouton « Marquer comme livrée » | **Absent** | ⬜ |
| I38 | Bandeau « demandes attendent leur prix » | **Absent** — c'est le travail de la patronne | ⬜ |

### I.8 — Hors ligne

| # | Scénario | Attendu | État |
|---|----------|---------|------|
| I39 | Mode avion : créer une demande | Enregistrée, visible immédiatement | ⬜ |
| I40 | Mode avion : fixer un prix puis encaisser | Les trois opérations s'empilent dans le bon ordre | ⬜ |
| I41 | Retour réseau | Tout part, **aucune opération bloquée** | ⬜ |
| I42 | Attendre un téléchargement complet | Rien n'est effacé, montants intacts | ⬜ |

> I40 vérifie la portée de file : le prix d'un dossier qui n'existe pas encore
> côté serveur doit attendre son dossier, sinon l'`UPDATE` ne trouve aucune
> ligne et le prix disparaît sans un mot.
>
> I42 est le piège du `pull_registry` : une colonne oubliée réécrit la ligne
> locale sans le champ et l'efface quelques secondes après sa création.

### I.9 — Petit écran (Pixel 4a)

| # | Scénario | Attendu | État |
|---|----------|---------|------|
| I43 | Formulaire de création, clavier ouvert | Le bouton Enregistrer reste atteignable | ⬜ |
| I44 | Feuille du montant, clavier ouvert | Le champ ne passe pas sous le clavier | ⬜ |
| I45 | Liste avec 6 dossiers | Le dernier n'est pas caché par le bouton flottant | ⬜ |

### Résultat de la semaine du 25/08 au 01/09 — validé le 01/09/2026

Boutique `A_Semaine`, huit journées hors ligne, 42 opérations envoyées d'un coup.

**Sept clôtures, sept écarts à zéro.** Caisse finale 211 400 F, réconciliée
ligne à ligne (6 400 de ventes + 280 000 d'entrées − 75 000 de sorties).
Contrôle croisé : 205 000 F d'espèces encaissées sur commandes = 205 000 F de
lignes de caisse. Le Mobile Money n'a pas touché le tiroir le jour du paiement,
et l'a alimenté le jour du retrait.

Bilan d'août et de septembre justes, y compris **la semaine à cheval sur les
deux mois** (31/08 → 06/09), qui apparaît des deux côtés avec ses seules
livraisons du mois consulté. PDF conforme.

**Le bug trouvé, et il ne l'aurait été autrement.** Le serveur refusait de
rembourser une commande annulée — or c'est le geste normal : la cliente annule,
on lui rend son acompte. Six jours de saisie locale n'ont rien signalé ; c'est
au moment de rejouer la file entière que le refus est apparu. Corrigé par
`202609010007_rembourser_une_annulee.sql`.

> **Une contrainte serveur se vérifie contre le PARCOURS RÉEL, pas contre
> l'intention.** L'ordre annuler-puis-rembourser n'avait jamais été rejoué de
> bout en bout.

### Ce qui reste NON testé, et le risque que ça porte

| # | Manque | Pourquoi ça compte |
|---|---|---|
| I46 | **Un vrai compte vendeur, sur un second téléphone** | Les 8 migrations RLS écrites cette semaine n'ont jamais été exercées par un vrai jeton vendeur. Le mode vendeur de l'émulateur bascule un drapeau local — il n'envoie pas les requêtes avec les droits d'un employé. C'est exactement ainsi qu'était apparu « l'upsert exige UPDATE **et** SELECT ». | ⬜ |
| I47 | Deux téléphones sur la même boutique, en même temps | Personne n'a vu ce que fait une commande modifiée des deux côtés | ⬜ |
| I48 | Petit écran (Pixel 4a), formulaires et feuilles | Trois bugs de contenu masqué déjà rencontrés dans ce projet | ⬜ |
| I49 | Le PDF sur un écran étroit / imprimé | Jamais regardé ailleurs que sur l'émulateur | ⬜ |
