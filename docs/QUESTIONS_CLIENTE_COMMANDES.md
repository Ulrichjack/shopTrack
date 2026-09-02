# Le bénéfice des commandes — ce qu'il faut demander à la cliente

> Préparé le 01/09/2026, avant l'entretien. Objectif : savoir ce qu'on peut
> calculer, et surtout ce qu'on ne peut pas.
>
> L'application sait aujourd'hui ce qui est **encaissé** et ce qui est **dû**.
> Elle ne sait pas ce qui est **gagné**, parce qu'il lui manque une seule
> information : **ce que la commande lui a coûté**.

## Comment mener l'entretien

Ne pas demander « voulez-vous une case pour le coût ? ». Elle répondra oui, et
la case restera vide.

Demander **« la dernière fois, vous avez fait quoi ? »**. Lui faire raconter une
commande réelle et récente, de chaque type, avec ses vrais chiffres. Ce qu'elle
sait dire de tête, on peut le calculer. Ce qu'elle doit aller chercher, elle ne
le saisira jamais.

**La question qui décide de tout, à poser en premier :**

> « Quand vous vendez un gâteau 150 000 F, est-ce que vous savez combien vous
> avez dépensé pour le faire ? »

Si la réponse est « non » ou « à peu près », **arrêter là** : on n'affichera
aucun bénéfice, et c'est plus honnête qu'un chiffre inventé.

---

## 1. Gâteau

**Le bénéfice** = prix − (ingrédients + décoration + support + livraison)

| À demander | Pourquoi ça change le code |
|---|---|
| Vous achetez la farine et les œufs **pour ce gâteau-là**, ou vous puisez dans un stock acheté en gros ? | Achat dédié → un montant par commande, simple. Stock commun → il faut répartir, c'est un autre chantier |
| Le carton, le support, les bougies, c'est compté dedans ? | Ce sont de petits montants qu'on oublie et qui font 10 % de la marge |
| Vous livrez ? Le transport, qui le paie ? | Si elle le paie sans le compter, sa marge affichée sera trop belle |

---

## 2. Objet décoratif sur mesure

**La question dominante, avant toutes les autres :**

> « L'objet, vous le fabriquez vous-même, ou quelqu'un le fait pour vous ? »

C'est la réponse qui change le plus de choses.

- **Elle fabrique** → le coût, c'est la matière (bois, tissu, peinture, vase,
  résine). Même schéma que le gâteau.
- **Un artisan fabrique** → le coût, c'est **ce qu'elle paie l'artisan**. C'est
  presque tout le coût, et c'est le chiffre le plus facile à saisir de tous les
  quatre : elle le connaît exactement, elle vient de le payer.

| À demander | Pourquoi |
|---|---|
| Vous payez l'artisan avant ou après ? | S'il est payé d'avance, c'est une sortie de caisse à enregistrer aussi |
| Il arrive qu'un objet soit raté et refait ? | Le deuxième essai double le coût — il faut pouvoir corriger le montant |

---

## 3. Formation

**Le bénéfice ne se calcule pas pareil.** Il y a une partie qui dépend du nombre
de participants, et une partie qui ne dépend de rien.

```
Bénéfice = (prix × nombre d'inscrits)
           − (kit remis × nombre d'inscrits)      ← varie
           − (salle + matière de démonstration)   ← fixe, même à 2 inscrits
```

| À demander | Pourquoi |
|---|---|
| Le prix est par personne, ou pour la session entière ? | Décide si un dossier = une inscription ou une session |
| Vous donnez un kit, des produits à emporter ? Ça vous coûte combien par personne ? | C'est le coût qui varie |
| Vous louez une salle ? Ça coûte pareil qu'il y ait 3 ou 15 personnes ? | C'est le coût fixe |
| **En dessous de combien d'inscrits vous perdez de l'argent ?** | Si elle sait répondre, on peut l'afficher — et c'est l'information la plus utile de tout le module |

---

## 4. Décoration événementielle

**C'est ici que se cache la plus grosse erreur possible.** Le matériel est de
deux natures, et les mélanger fausse tout.

| Nature | Exemples | Est-ce un coût de l'événement ? |
|---|---|---|
| **Consommé** | ballons, fleurs, rubans, bougies, mousse florale | **Oui** — jeté après |
| **Réutilisable** | arches, vases, tentures, guirlandes, chandeliers | **Non** — resservira trente fois |

Si elle compte une arche à 200 000 F dans le coût d'une décoration, cet
événement affiche une perte énorme et **les trente suivants paraissent
gratuits**. Ni l'un ni l'autre n'est vrai. Le matériel réutilisable est un
achat de matériel, pas un coût de commande.

| À demander | Pourquoi |
|---|---|
| Sur la dernière décoration, qu'est-ce que vous avez **jeté** à la fin ? | C'est ça, le coût réel |
| Qu'est-ce que vous avez **remporté** pour resservir ? | À exclure du coût |
| Vous prenez des aides pour le montage ? Vous les payez combien ? | Souvent le premier poste de dépense, et toujours oublié |
| Le transport du matériel jusqu'à la salle ? | Idem |
| On vous demande une caution à la salle ? | Ce n'est pas une dépense — l'argent revient. À ne surtout pas compter comme un coût |

---

## 5. « Et si elle propose autre chose ? »

| À demander | Pourquoi |
|---|---|
| En dehors de ces quatre, vous faites autre chose sur commande ? | Location de matériel ? Traiteur ? Vente de savons finis ? |
| Quand une cliente demande quelque chose que vous n'avez jamais fait, vous faites quoi ? | Savoir si les métiers bougent souvent |
| Depuis un an, vous avez ajouté une nouvelle activité ? | Si oui → les **catégories personnalisées** valent le coup. Si non → quatre suffisent, et on ne construit rien |

---

## Ce qu'on construira selon les réponses

**Deux champs sur le dossier, pas quatre formulaires.** Ils couvrent les quatre
métiers sans en dupliquer un seul :

| Champ | Ce qu'il contient | Qui l'utilise |
|---|---|---|
| **Ce que la matière m'a coûté** | ingrédients, bois, tissu, ballons jetés, kits de formation | les quatre |
| **Ce que j'ai payé à quelqu'un** | l'artisan, les aides du montage, la salle | objets, décoration, formation |

Saisis à la livraison, pas à la commande : au moment de commander elle ne sait
pas encore ce qu'elle aura dépensé.

Et sous le champ, une phrase qui évite l'erreur de l'arche :

> *N'y mets pas ce que tu vas resservir. Une arche, des vases, une tenture ne
> sont pas un coût de cette commande.*

**Si elle ne sait répondre à rien** : on ne construit aucun de ces champs. L'app
affiche l'encaissé et le dû, et on lui dit franchement qu'elle ne saura pas si
elle gagne. Un bénéfice faux coûte plus cher que pas de bénéfice du tout — c'est
la leçon qu'on a payée une journée sur le mode inventaire.
