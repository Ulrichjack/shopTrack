# ShopTrack — préparation de Google Play

État : préparation locale, pas une validation de conformité ni une publication.
Exigences consultées le 25 septembre 2026. Recontrôler dans Play Console au dépôt.

## 1. Ce qui est préparé

- Écrans « Informations légales », « Confidentialité » et « Supprimer mon compte ».
- Accès avant connexion, à l'inscription, au premier mot de passe vendeur et au profil.
- Lecture des textes hors ligne, sans accès aux données d'une boutique.
- Préparation d'e-mails d'accès, de rectification et de suppression vers le contact
  fourni par l'éditeur ; copie de secours si aucune messagerie n'est disponible.
- Accès aux licences des composants Flutter depuis les informations légales.
- Une source commune pour les écrans et les pages HTML :
  `assets/legal/informations_fr.json`. Les textes restent explicitement en brouillon.
- Les CGU de travail et les informations de l'éditeur restent dans
  `DOSSIER_JURIDIQUE_BROUILLON.md`. Aucune acceptation de CGU inachevées n'est demandée.

Les e-mails ne sont pas envoyés par ShopTrack. Aucun compte, donnée ou fichier
Supabase n'est supprimé par ce parcours. Il faut un traitement réel des demandes
par l'éditeur avant de considérer l'exigence de suppression comme satisfaite.

## 2. Décisions et vérifications avant publication

| Point | Action nécessaire |
|---|---|
| Établissement de l'éditeur | Confirmer les mentions d'identité et d'adresse de l'éditeur exigées par la fiche Play et les textes légaux |
| Offre | Choisir bêta gratuite ou abonnement ; vérifier les règles de paiement Play applicables avant d'ajouter un paiement |
| Données et finalités | Définir et documenter la base légale par traitement, les rôles boutique/éditeur et les accords avec les prestataires |
| Conservation | Fixer les durées par catégorie et les appliquer techniquement ; inclure journaux, demandes de droits, stockage et sauvegardes |
| Suppression | Tester de bout en bout une demande, la vérification d'identité, la suppression/anonymisation et la réponse, sur des données fictives |
| Hébergement | Vérifier région, contrat Supabase, sous-traitants et éventuels transferts ; ne pas déduire les garanties de la seule région du serveur |
| Photos | Le code appelle `getPublicUrl` pour `product-photos`. Auditer le bucket et ses policies, puis choisir entre photos strictement publiques de produits ou accès privé avec migration adaptée |
| Confidentialité locale | Contrôler stockage des sessions, journaux et sauvegardes locales ; ne pas annoncer du chiffrement local ou de bout en bout sans preuve |
| Droits et incidents | Mettre en place un registre de traitements proportionné, un suivi des demandes et une procédure en cas de violation |
| CGU | Finaliser les engagements et l'offre avant toute acceptation versionnée ; couvrir les vendeurs et les comptes existants |

## 3. Traiter les demandes de droits

Le contact est celui du dossier juridique. Le vérifier réellement et le surveiller.

1. Enregistrer la réception, le type de demande, l'échéance applicable et le minimum
   d'informations nécessaire. Si le RGPD s'applique, organiser la réponse sans retard
   injustifié et en principe sous un mois, avec les exceptions prévues par l'article 12.
2. Vérifier le demandeur de façon proportionnée. Le numéro seul n'est pas une preuve :
   il n'est pas vérifié par SMS dans l'application actuelle. Ne jamais demander le PIN
   ou le mot de passe par e-mail. Concevoir et tester un canal de vérification sûr.
3. Identifier les comptes, boutiques et données concernés. Distinguer le compte propre,
   les données de la boutique et les droits d'autres personnes, notamment des employés.
4. Pour l'accès, préparer un export limité aux données auxquelles le demandeur a droit.
   La sauvegarde locale actuelle n'est pas un export RGPD : elle couvre plusieurs tables
   métier, peut inclure la file de synchronisation et ne couvre pas toutes les données.
5. Pour une suppression, établir la liste de ce qui sera supprimé, anonymisé ou conservé
   avec le motif précis et la durée. Inclure Auth, relations métier, Storage, caches et
   sauvegardes. Ne pas conserver tout l'historique par défaut sans justification.
6. Tester sur une base de test les contraintes, cascades et comptes partagés avant
   d'exécuter la procédure. Ne pas supprimer un utilisateur Auth à l'aveugle.
7. Traiter les sessions et appareils hors ligne : les anciennes files ne doivent pas
   recréer les données supprimées et les copies locales doivent avoir un sort défini.
8. Confirmer l'exécution et expliquer les éventuelles conservations. Conserver seulement
   la preuve minimale justifiée du traitement de la demande.

Une simple désactivation, un retrait de vendeur ou une désinstallation ne vaut pas
suppression du compte et des données associées.

## 4. Pages web publiques

Pour relire les pages localement :

```bash
python3 scripts/generer_pages_juridiques.py --apercu
python3 scripts/generer_pages_juridiques.py --apercu --verifier
```

Fichiers générés dans `website/legal/` : `editeur.html`, `confidentialite.html`,
`suppression-compte.html`. Aucun hébergement ou nom de domaine n'est créé.
Les pages sont autonomes, sans traceur, police externe ou connexion obligatoire.

Après finalisation du contenu et vérification des pratiques réelles, changer la
version et le statut `draft` dans la source puis générer sans `--apercu`. Ce statut
est un garde-fou de préparation, pas une certification juridique. Les aperçus ne
doivent pas servir de politique définitive dans Play Console.

Google demande une politique disponible sur une URL publique active, non limitée
géographiquement, non modifiable par les visiteurs et non fournie seulement en PDF.
Il faut aussi une URL permettant de demander la suppression sans réinstaller l'app.
Vérifier cette page depuis un navigateur déconnecté et tester le contact réellement.

## 5. Compte et fiche Google Play

1. Créer ou compléter un compte développeur personnel avec la véritable identité de
   l'éditeur et les coordonnées demandées. Google indique un paiement unique de 25 USD,
   des vérifications d'identité et, pour les nouveaux comptes personnels, d'appareil Android.
2. Lire les informations que Google affichera publiquement avant de valider le profil.
3. Choisir les pays de diffusion. Recommandation initiale : Cameroun ; une démo fictive
   pour recruteurs peut être préparée séparément, elle n'est pas implémentée ici.
4. Préparer nom, description, icône, visuel promotionnel et captures de vraies interfaces
   avec des données fictives. Aucun numéro ni chiffre d'affaires de clients dans les captures.
5. Remplir audience cible, classification du contenu, publicité et accès à l'application.
6. Fournir aux examinateurs un compte dédié avec données fictives et accès aux modules
   à examiner ; vérifier les instructions de connexion et les éventuelles étapes PIN.

## 6. Préparer la déclaration « Sécurité des données »

Cette grille est un inventaire de départ, pas un formulaire prêt à soumettre.
Examiner aussi les SDK et les journaux des prestataires. Ne pas cocher « aucune donnée
collectée » : des données sont transmises à Supabase.

| Données observées dans le code | Points à déclarer ou vérifier |
|---|---|
| Numéro, identifiant Auth, rôles | Informations personnelles / identifiants ; gestion des comptes |
| Coordonnées clients, notes et commandes | Informations personnelles et contenus saisis ; fonctionnalité métier |
| Ventes, caisse, paiements, historiques | Catégories financières, achats ou activité selon les définitions exactes du formulaire |
| Photos de produits | Images envoyées au serveur lorsque cette fonction est utilisée ; liens publics à auditer |
| Dates d'opérations et de connexion | Activité et métadonnées de compte ; usages réels à préciser |
| Journaux techniques, IP côté hébergeur | Vérifier collecte, durée et finalités réelles chez les prestataires |

Les notions de « collecte » et « partage » du formulaire Play ont leurs propres
définitions : analyser les exceptions pour prestataires, sans conclure que tout envoi
à Supabase est automatiquement un partage public ou qu'il ne faut rien déclarer.

## 7. Binaire, sécurité et tests

- Garder `cm.shoptrack.shoptrack` et la clé de signature existante ; les secrets de
  signature ne doivent jamais être ajoutés au dépôt ni partagés avec les testeurs.
- Produire un Android App Bundle signé (`flutter build appbundle --release`) et
  configurer Play App Signing avec une stratégie compatible avec les APK déjà diffusés.
- Vérifier dans l'artefact final le niveau cible Android : depuis le 31 août 2026,
  Google demande Android 16 / API 36 au minimum pour les nouvelles apps mobiles.
  Le projet délègue actuellement `targetSdk` au SDK Flutter installé, dont la
  configuration locale indique 36. Cela ne remplace pas le contrôle du bundle final.
- Vérifier également les bibliothèques natives et la compatibilité avec les pages
  mémoire de 16 Ko ; ne pas déduire cette compatibilité du seul targetSdk.
- Exécuter `flutter analyze`, `flutter test`, puis tester le bundle distribué par
  Play sur de vrais appareils : caméra, connexion, changement de compte, modes patron
  et vendeur, hors ligne/en ligne, erreurs de synchronisation et reprise.
- Ajouter les essais de confidentialité : accès croisés refusés, lecture hors ligne
  des textes, absence de messagerie, demandes de suppression et appareils déconnectés.
- Pour un compte personnel créé après le 13 novembre 2023 : au moins 12 testeurs
  inscrits au test fermé pendant 14 jours consécutifs, puis demander l'accès à la
  production. Le délai seul ne garantit pas l'approbation ; documenter les essais.

## 8. Sources officielles

- [Inscription, frais et vérifications Play Console](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en).
- [Tests des nouveaux comptes personnels](https://support.google.com/googleplay/android-developer/answer/14151465?hl=fr).
- [Niveau API cible](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en).
- [Suppression de compte](https://support.google.com/googleplay/android-developer/answer/13327111).
- [Règlement Google Play](https://support.google.com/googleplay/android-developer/answer/17517561).
- [Déclaration de sécurité des données](https://support.google.com/googleplay/android-developer/answer/10787469).
- [Compatibilité Android 16 Ko](https://developer.android.com/guide/practices/page-sizes).
- [RGPD, droits des personnes](https://www.cnil.fr/fr/reglement-europeen-protection-donnees/chapitre3).

La publication dépend des points ouverts ci-dessus. Ni les pages générées ni les
tests du code ne suffisent à annoncer « conforme RGPD » ou « approuvé Google Play ».
