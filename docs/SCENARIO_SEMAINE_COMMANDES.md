# Semaine complète — 26 août au 2 septembre 2026

> Boutique **`B_Semaine`**, mode simple, module Commandes activé, **hors ligne**
> du début à la fin. Base zéro : chaque chiffre est exact au franc près.
>
> Deux articles : **Savon** (achat 500, vente 800) et **Huile** (achat 1 200,
> vente 1 500). Marge de 300 sur les deux, ça simplifie la vérification.
>
> La semaine traverse la bascule de mois **exprès**. Le 31 août est un lundi :
> la dernière semaine d'août déborde sur septembre, et aucune semaine ordinaire
> ne touche ce cas.

## Avant de commencer, EN LIGNE

1. Créer **`B_Semaine`** · Réglages → activer **Commandes avec acompte**
2. Stock → **Savon** achat 500 / vente 800 / qté 50
3. Stock → **Huile** achat 1 200 / vente 1 500 / qté 30
4. Réglages → créer un **compte vendeuse** (pour le jour 5)

Puis `./scripts/emu.sh hors-ligne` et `./scripts/emu.sh jour 26`.

## Jour par jour

| Jour | Ce que tu fais | Caisse le soir |
|---|---|---|
| **Mer 26/08** | 3 savons (2 400) · commande **Ngo Bikoi**, gâteau **150 000**, promise le **30/08** · acompte **40 000 espèces** · clôturer | **42 400** |
| **Jeu 27/08** | Demande **Sandrine**, objet décoratif, **sans prix** · 2 huiles (3 000) · sortie de caisse **Transport 1 500** · clôturer | **43 900** |
| **Ven 28/08** | Prix Sandrine → **50 000** · acompte **20 000 Orange Money** · commande **Rose Manga**, formation **30 000** payée d'un coup · 1 savon (800) · clôturer | **74 700** |
| **Sam 29/08** | **Livrer Rose Manga** + coût **9 000** · commande **Carine**, **décoration 200 000** · acompte **50 000 espèces** · 2 savons (1 600) · clôturer | **126 300** |
| **Dim 30/08** | **MODE VENDEUSE** : 3 huiles (4 500) · demande **Julienne**, gâteau, sans prix · encaisser **30 000** sur Ngo Bikoi · sortie **Remise à la patronne 50 000** · clôturer | **110 800** |
| **Lun 31/08** | Patronne : **le bandeau retard doit apparaître** (Ngo Bikoi promise le 30) · retirer les **20 000 Orange Money** · acompte **10 000 MTN MoMo** sur Carine · 1 savon (800) · clôturer | **131 600** |
| **Mar 01/09** | Solde Ngo Bikoi **80 000 espèces** · **livrer** + coût **45 000** · **annuler Carine** (motif) · rembourser **50 000 espèces** puis **10 000 MTN MoMo** · clôturer | **161 600** |
| **Mer 02/09** | Encaisser **20 000** sur Sandrine (elle en devra encore 10 000) · **livrer** + coût **12 000** · **corriger** la commande de Julienne (date + description) · clôturer | **181 600** |

Puis `./scripts/emu.sh fin`.

## Ce que le jour 5 doit prouver (mode vendeuse)

Elle **peut** : vendre, encaisser un acompte, enregistrer une demande, faire une
sortie de caisse, clôturer, fixer un prix (gâteau, objet, formation).

Elle ne **doit pas voir** : le coût d'une commande, le bénéfice, « Annuler la
commande », le prix d'une **décoration**, « Retrait patron » dans les sorties
(elle a « Remise à la patronne » à la place).

## Ce que le bilan doit dire

### Août — BOUTIQUE
```
Ventes            13 100
Dépenses           1 500      la remise à la patronne n'en est pas une
Bénéfice           2 100      3 600 de marge − 1 500
```

### Août — COMMANDES
```
Chiffre d'affaires   30 000    Rose Manga seule, livrée le 29/08
Ce que ça a coûté     9 000
Bénéfice             21 000
```

### Septembre — COMMANDES
```
Chiffre d'affaires  200 000    Ngo Bikoi 150 000 + Sandrine 50 000
Ce que ça a coûté    57 000    45 000 + 12 000
Bénéfice            143 000

Encore dû            10 000
  Sandrine · déjà livrée       10 000   ← en rouge

SEMAINE PAR SEMAINE
Du 31/08 au 06/09 · 2 livrées   143 000
```

### Ce qui ne doit PAS apparaître
- Carine, annulée, dans un chiffre d'affaires
- Un bénéfice négatif après son remboursement
- Julienne, sans prix, dans « Encore dû »
- La remise à la patronne comme une dépense

## Contrôles à passer à la fin

```bash
./scripts/emu.sh commandes    # espèces commandes == lignes de caisse
./scripts/emu.sh etat         # la file doit tomber à 0
```

Puis le **PDF d'août** : sortir, vérifier qu'il n'est pas coupé, et que le bloc
COMMANDES y est avec la liste nommée des clientes qui doivent.
