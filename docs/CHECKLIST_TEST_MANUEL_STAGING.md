# ShopTrack TEST — vérification manuelle sur téléphone

À faire sur **ShopTrack TEST**, avec des boutiques et noms fictifs. Ne pas utiliser
le compte ni les données d'un client. Noter pour chaque échec : écran, geste,
résultat attendu, résultat obtenu, heure, capture d'écran et état du réseau.

**Ordre conseillé :** mode simple → commandes → inventaire périodique. Utiliser
si possible une boutique fictive différente pour chaque mode : les ventes et
recettes déjà enregistrées restent dans l'historique quand on change de mode.
Les modules Commandes et Inventaire périodique ne peuvent pas être actifs en
même temps. Ne pas changer le mode d'une boutique de client.

## 0. Préparer le test

- [ ] Vérifier que l'icône ouverte dit **ShopTrack TEST** et que l'application
  normale des clients reste fermée.
- [ ] Installer le dernier APK **staging** avant de tester une correction récente
  (le choix « Galerie » n'est pas dans l'APK installé lors du test du 28/10).
- [ ] Se connecter à un compte fictif staging. Vérifier que la boutique affichée
  est la boutique fictive, puis ouvrir **Profil → État de synchronisation** :
  zéro opération en attente avant de commencer.
- [ ] Préparer un produit réel avec code-barres EAN, un QR imprimé ou affiché
  sur un autre écran, une photo dans la galerie et, si possible, un second
  téléphone pour les essais entre appareils.

## 1. Mode simple — boutique fictive

- [ ] Ajouter un produit avec prix d'achat, prix de vente et stock initial.
  Vérifier la fiche et la valeur du stock.
- [ ] Sur la fiche produit, choisir **Appareil photo**, prendre une photo,
  enregistrer puis rouvrir la fiche. Refaire avec **Galerie** ; remplacer la
  photo d'un produit existant et vérifier qu'elle reste après redémarrage.
- [ ] Scanner le code EAN puis le QR dans **Nouvelle vente**. Vérifier la
  reconnaissance et la sélection du bon produit ; tester la saisie manuelle
  et le refus d'accès caméra.
- [ ] Vendre une unité. Vérifier prix, bénéfice, journal de caisse et stock
  décrémenté d'une seule unité.
- [ ] Couper Wi-Fi **et** données mobiles, vendre une autre unité, fermer puis
  rouvrir ShopTrack TEST. Vérifier que la vente et le stock restent visibles.
- [ ] Rétablir le réseau. Attendre **0 opération en attente** ; vérifier qu'il
  n'y a ni vente doublée ni second décompte du stock.
- [ ] Si un second téléphone est disponible, ouvrir le même compte staging,
  synchroniser et comparer ventes, stock et photos.
- [ ] Sur le nouvel APK, ouvrir le menu fichier de **Mon stock**, télécharger
  le modèle CSV, l'ouvrir dans Excel, exporter le catalogue puis le relire.
  Importer une nouvelle ligne fictive valide ; vérifier le produit et la synchro.
  Réimporter le même fichier : le doublon doit être refusé avant tout ajout.
- [ ] Faire une clôture de caisse avec le montant réel, puis avec un manque
  ou surplus fictif dans une autre journée de test. Vérifier l'écart dans le
  bilan et le PDF. Ne pas clore une journée réelle d'un client.

## 2. Commandes avec acompte — séparément de l'inventaire

- [ ] Dans **Profil → Réglages de la boutique**, désactiver Inventaire
  périodique, puis activer Commandes avec acompte. Vérifier l'onglet Commandes.
- [ ] Créer une commande fictive avec prix convenu. Vérifier qu'avant paiement,
  la caisse n'augmente pas et que tout le prix reste à payer.
- [ ] Encaisser un acompte en espèces : seul le montant payé entre en caisse ;
  le reste dû diminue du même montant.
- [ ] Tester un paiement Orange Money ou MTN MoMo : il doit figurer dans la
  commande sans être ajouté au tiroir d'espèces.
- [ ] Tester remboursement, correction du prix et livraison sur une commande
  fictive ; vérifier l'historique et le solde après chaque geste.
- [ ] Couper le réseau pendant une opération, puis le rétablir et contrôler
  la file de synchronisation et les montants sur un second appareil si possible.

## 3. Inventaire périodique — mode utilisé par Gildas

- [ ] Désactiver Commandes avec acompte, activer Inventaire périodique.
  Vérifier que l'onglet Ventes disparaît et que l'onglet Inventaire apparaît.
- [ ] Créer ou choisir un produit fictif, saisir la recette d'une journée,
  vérifier l'accueil et la possibilité de corriger cette recette.
- [ ] Faire un **premier comptage** physique : le stock théorique doit rester
  caché pendant la saisie. Vérifier « Mes comptages ».
- [ ] Importer un produit par CSV avec la colonne `quantite` vide : il doit
  apparaître dans le catalogue mais demander son premier comptage. Essayer une
  quantité non vide : le fichier doit être refusé.
- [ ] À une date ultérieure, enregistrer un deuxième comptage, avec un
  approvisionnement et une perte fictifs entre les deux si possible. Vérifier
  quantités présumées vendues, coût, recette et écart dans le rapport/PDF.
- [ ] Tester « Déclarer une perte » (casse, périmé ou autre) ; vérifier qu'elle
  est attribuée à la bonne période et ne devient pas une vente.
- [ ] Avec deux boutiques fictives et deux comptes autorisés, envoyer puis
  confirmer un transfert. Vérifier les quantités de chaque côté, y compris
  un écart entre quantité envoyée et reçue.
- [ ] Répéter recette et comptage hors ligne, puis vérifier la reprise sans
  doublon et **0 opération en attente** après reconnexion.

## 4. Vente par unités / cycles d'approvisionnement — module optionnel

Ce module est **masqué pour les nouvelles boutiques** dans les réglages actuels.
Le tester seulement après que nous avons préparé une boutique fictive dédiée
sur staging ; ne cherche pas à l'activer sur une boutique réelle.

- [ ] Vérifier l'onglet Cycles et créer un produit fictif (ex. œufs) avec ses
  unités de vente, par exemple unité, plateau et carton. Vérifier les ratios.
- [ ] Créer un arrivage/cycle avec quantité et coût d'achat. Vérifier le stock
  disponible dans chaque unité.
- [ ] Vendre une unité puis un lot ; vérifier la conversion, le prix, le
  bénéfice et le stock restant. Essayer de vendre plus que le stock : refus.
- [ ] Déclarer une perte ; vérifier son effet dans le stock et le rapport.
- [ ] Fermer le cycle, ouvrir le rapport et comparer les chiffres au calcul
  manuel. Vérifier le comportement d'une vente après fermeture.
- [ ] Faire un cycle ou une vente hors ligne, redémarrer, reconnecter et
  contrôler qu'aucune opération ni quantité n'est doublée.

## 5. Accès et fin de test

- [ ] Connecter un compte vendeur fictif : vérifier qu'il voit seulement sa
  boutique et qu'il ne peut pas ouvrir les écrans ou données réservés au patron.
- [ ] Vérifier les textes légaux hors ligne, la déconnexion/reconnexion et la
  persistance des données après redémarrage du téléphone.
- [ ] Signaler les résultats, même si tout passe. Conserver les données
  fictives staging pour reproduire un éventuel défaut ; ne rien effacer dans
  la base des clients.

### Fiche de retour à copier pour chaque problème

```text
Mode et boutique fictive :
Étape cochée :
Téléphone / version ShopTrack TEST :
En ligne ou hors ligne :
Gestes effectués :
Résultat attendu :
Résultat obtenu :
Heure et capture d'écran :
État de synchronisation (nombre d'opérations en attente) :
```

Le test automatisé du 28/10 a déjà couvert : inscription, produit, vente en
ligne/hors ligne, reprise de synchro, commande avec acompte espèces, recette,
premier comptage et ouverture de la caméra du scanner. Le scanner avec un vrai
code, la galerie sur le nouvel APK, le second comptage et les scénarios à deux
appareils restent à confirmer par un humain.
