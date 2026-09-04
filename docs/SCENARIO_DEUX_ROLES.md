# Le passage de relais — patronne et vendeuse sur la même boutique

> Boutique **`C_Semaine`**, mode simple, module Commandes activé.
> **EN LIGNE du début à la fin**, et sans toucher à la date.

## Pourquoi ce scénario ne simule pas une semaine

Changer de compte exige le réseau. Une semaine hors ligne ne permet donc
**aucune alternance de rôle** — on resterait connecté au même compte sept jours
durant, et le partage du travail ne serait jamais testé.

Et deux boutiques séparées, une par rôle, ne testeraient rien non plus : chacun
travaillerait seul. Or c'est exactement le passage de l'un à l'autre qui peut
casser.

Ce scénario abandonne donc le calendrier — déjà validé ailleurs (semaine hors
ligne, bascule de mois, découpage hebdomadaire, file de 42 opérations envoyée
d'un coup) — pour se concentrer sur **une seule question : qui peut quoi, et
que voit l'autre après**.

Quatre blocs, trois changements de compte. Tout se passe aujourd'hui.

## Avant

Créer **`C_Semaine`** · activer **Commandes avec acompte** · **Savon** 500/800
qté 60 · **Huile** 1 200/1 500 qté 40 · créer le **compte vendeuse**.

Puis se **déconnecter** et se reconnecter avec le compte vendeuse.

---

## BLOC 1 — 👩‍🦰 LA VENDEUSE ouvre la boutique

| # | Action | Ce qui doit se passer |
|---|---|---|
| 1 | Vendre **8 savons** (6 400) | — |
| 2 | Commande **Mme Atangana**, gâteau, promise **demain** | **Aucun champ prix** dans le formulaire |
| 3 | Sur sa fiche : **Fixer le prix 120 000** | ✅ **Accepté** — un gâteau a un tarif |
| 4 | Encaisser **50 000 espèces** | Reste 70 000 |
| 5 | Commande **Mme Bilong**, **décoration**, promise **demain** | — |
| 6 | Ouvrir sa fiche | ❌ **Aucun bouton de prix** — une décoration se chiffre au cas par cas |
| 7 | Sur Atangana : encaisser **20 000 Orange Money** | La caisse **ne bouge pas**, la carte « PAS ENCORE DANS LA CAISSE » apparaît |
| 8 | Toucher la carte, **retirer les 20 000** | La caisse monte de 20 000 |
| 9 | Sortie de caisse **Transport 2 000** | ❌ **« Retrait patron » absent** de la liste, « Remise à la patronne » présente |
| 10 | Regarder la barre du bas | ❌ **Aucun onglet Bilan** |
| 11 | Clôturer | Caisse **74 400** |

**→ Se déconnecter, se reconnecter en patronne.**

---

## BLOC 2 — 👑 LA PATRONNE regarde de chez elle

| # | Action | Ce qui doit se passer |
|---|---|---|
| 12 | Ouvrir Commandes | Bandeau **« 1 demande attend son prix »** (Bilong) |
| 13 | Fixer le devis Bilong à **180 000** | ✅ Accepté — elle seule peut |
| 14 | Corriger le nom en **« Mme Bilong Épouse Kamga »** | Le nom change partout, y compris au journal de caisse |
| 15 | Sur Atangana, **reculer la date promise à hier** | — |
| 16 | Revenir à la liste | Le **bandeau rouge de retard** sort, avec le nom d'Atangana |

**→ Se déconnecter, se reconnecter en vendeuse.**

---

## BLOC 3 — 👩‍🦰 LA VENDEUSE reprend

| # | Action | Ce qui doit se passer |
|---|---|---|
| 17 | Ouvrir Commandes | Elle voit **le même bandeau de retard** que la patronne |
| 18 | Bilong : encaisser **60 000 espèces** | Reste 120 000 |
| 19 | Atangana : encaisser le solde **50 000 espèces** | Soldée |
| 20 | **Marquer livrée** | ✅ Accepté, et **aucune feuille de coût ne s'ouvre** |
| 21 | Rouvrir sa fiche | ❌ Ni bandeau orange, ni bouton coût, ni ligne « J'ai gagné » |
| 22 | Ouvrir Bilong | ❌ **Aucun bouton « Annuler »** |
| 23 | Vendre **3 huiles** (4 500) | — |
| 24 | Sortie **Remise à la patronne 50 000** | — |
| 25 | Clôturer | Caisse **138 900** |

**→ Se déconnecter, se reconnecter en patronne.**

---

## BLOC 4 — 👑 LA PATRONNE fait les comptes

| # | Action | Ce qui doit se passer |
|---|---|---|
| 26 | Ouvrir Atangana | **Bandeau orange** « Livrée, mais tu n'as pas dit ce qu'elle t'a coûté » |
| 27 | Saisir **38 000** | La fiche affiche **« J'ai gagné 82 000 »** |
| 28 | Ouvrir Bilong → **Annuler** avec motif | Elle passe en **ANNULÉES**, barrée, motif visible |
| 29 | **Rembourser 60 000 espèces** | Caisse **78 900** |
| 30 | Ouvrir le **Bilan**, puis générer le **PDF** | Voir ci-dessous |

---

## Ce que le bilan doit dire

```
BOUTIQUE
  Ventes                10 900
  Dépenses               2 000     le transport seul
  Bénéfice               1 300     3 300 de marge − 2 000

COMMANDES
  Chiffre d'affaires   120 000     Atangana seule
  Ce que ça a coûté     38 000
  Bénéfice              82 000
  Encore dû                  0
```

Bilong, annulée, **nulle part** dans les chiffres. Et le bénéfice ne doit
**pas** devenir négatif après son remboursement de 60 000.

## Contrôle final

```bash
./scripts/verifier.sh C_Semaine
```

Attendu : **100 000 F d'espèces sur commandes = 100 000 F de lignes de caisse**,
et deux comptes distincts dans « qui a fait quoi » — un `owner`, un `seller`.
