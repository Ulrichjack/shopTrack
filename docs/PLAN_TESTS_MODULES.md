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
| A7 | Terminer un cycle | Résultat figé, stock intact | ⬜ |
| A8 | Vendre après fermeture du dernier cycle | Refus « aucun cycle ouvert », stock intact | ⬜ |
| A9 | Rouvrir un cycle après fermeture | Vente possible à nouveau, nouveau coût unitaire | ⬜ |

## B. Module A — cas limites et erreurs

| # | Scénario | Attendu | État |
|---|----------|---------|------|
| B1 | Vendre plus que le stock | Refus avant validation (encadré rouge) | ⬜ |
| B2 | Perte supérieure au stock | Refus explicite | ⬜ |
| B3 | Unité nommée « 30 » (nombre) | Refusé : « un mot, pas un nombre » | ✅ |
| B4 | Ratio 0 ou négatif | Refusé | ⬜ |
| B5 | Supprimer une unité **déjà utilisée** | Refus + message | ⬜ |
| B6 | Supprimer une unité **jamais utilisée** | Suppression OK | ✅ |
| B7 | Produit sans unité définie | Message clair, pas de plantage | ⬜ |
| B8 | Quantité reçue 0 / coût 0 | Pas de division par zéro | ⬜ |
| B9 | Prix de vente 0 (don, casse offerte) | Accepté, perte affichée en rouge | ⬜ |
| B10 | Prix inférieur au coût | Perte annoncée **avant** validation | ⬜ |
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
| F2 | Oublier une journée | Clôture forcée de la plus ancienne | ⬜ |
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

## Ordre conseillé pour la suite

1. **B (cas limites)** — évite les mauvaises surprises chez le client.
2. **A7–A9** — fermeture de cycle ; il manque encore le signalement
   « cycle épuisé » et la **réouverture** d'un cycle fermé par erreur
   (aujourd'hui irréversible).
3. **F2–F5** — clôtures rattrapées, livrées mais jamais utilisées.
4. **E, G** — non-régression et arbitrage sur la visibilité des coûts d'achat
   pour un vendeur.
