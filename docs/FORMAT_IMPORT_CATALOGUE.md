# Import/export du catalogue — format simple proposé

**État : fonction codée, tests du format passés ; nouvel APK staging à installer
et vérifier sur un vrai téléphone avant usage.**
Le but est de commencer par le catalogue et le stock, sans importer ventes,
caisse, clients, commandes, comptages ou sauvegarde complète de la base.

## Fichier

CSV UTF-8, séparateur `;`, une ligne par produit. Excel peut l'ouvrir et
l'enregistrer. Garder exactement cette première ligne :

```csv
nom;prix_achat;prix_vente;quantite;alerte_stock_bas;code_barres;unite
Savon test;500;750;12;2;TEST-001;piece
Riz test;10000;12000;;2;TEST-002;sac
```

`nom` et `prix_vente` sont obligatoires. Les montants et quantités sont des
entiers FCFA sans espaces ni symbole. `prix_achat`, `alerte_stock_bas`,
`code_barres` et `unite` sont facultatifs. Un code-barres fourni doit être
unique dans la boutique. Une ligne invalide doit être montrée avec son numéro
avant tout enregistrement ; aucun écrasement automatique d'un produit existant.
Les champs texte commençant par `=`, `+`, `-` ou `@` sont refusés à l'import,
car Excel pourrait les exécuter comme des formules. L'export neutralise aussi
ces valeurs si elles existaient déjà dans le catalogue.

| Mode | Colonne `quantite` | Mise en route du stock |
|---|---|---|
| Simple | Entier obligatoire, zéro accepté | Stock initial du produit |
| Inventaire périodique | Laisser vide | Premier comptage physique dans l'app |
| Cycles / unités | Laisser vide | Premier approvisionnement/cycle dans l'app |

Le module **Commandes avec acompte** est indépendant de ces trois modes. Son
activation ne change pas le format CSV : l'import ajoute des produits au
catalogue de la boutique ouverte, jamais des commandes ou des acomptes.
Le menu CSV n'est affiché qu'avec l'accès Patron. Cette fonction est pour
l'instant disponible dans l'application Android, pas encore sur le web.

Dans les deux derniers modes, le zéro technique d'une nouvelle ligne ne doit
pas être présenté comme un vrai comptage ou un arrivage. Les unités dérivées
(plateau, carton, etc.) se configurent dans le module Cycles après l'import.

Dans **Mon stock**, le menu fichier permet de télécharger le modèle, exporter
le catalogue ou importer un CSV. L'import vérifie le fichier entier, refuse
les noms ou codes-barres déjà présents, limite à 100 produits et demande une
confirmation avant l'ajout. Il **crée seulement** : aucun produit existant
n'est modifié. Si une erreur réseau ou de base arrive pendant l'ajout, le
message donne le nombre déjà ajouté ; reprendre seulement les lignes restantes.
L'export reprend les mêmes colonnes. Une mise à jour en masse des produits
existants demandera plus tard un identifiant stable et un aperçu des écarts.
