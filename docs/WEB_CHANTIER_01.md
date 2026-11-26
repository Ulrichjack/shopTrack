# Web de test — première étape

Le premier frontend Flutter Web est dans `lib/web/` et se construit avec
`bash scripts/construire_staging_web.sh`. Il utilise **uniquement** le projet
Supabase staging `bjrmapcwfzrrvutozyfx`. Les trois boutiques de validation
reprennent des données métier de production après masquage des identités et
contacts ; la base de production reste en lecture seule. L'APK Android staging
utilise le même projet. Le build statique sort dans `build/web` ; `web/vercel.json`
prépare une réécriture vers `index.html` pour l'hébergement statique temporaire.
Aucun déploiement Vercel n'est effectué par ce script.

## Fonctionnel maintenant

- Inscription d'un compte fictif avec création de boutique, et connexion avec
  le même numéro et mot de passe que sur Android staging.
- Choix d'une boutique autorisée par `shop_members`.
- Lecture des produits non archivés avec prix de vente et quantité depuis
  Supabase ; actualisation manuelle ; déconnexion.
- Vignette photo dans le catalogue ; un clic ouvre la fiche avec un grand cadre
  photo en haut, prix de vente, stock et QR du produit. Le bouton de correction
  de la fiche reste réservé au propriétaire. Les photos proviennent de Storage
  staging, comme les données de ces boutiques de test.
- Création d'un produit avec prix, unité, code-barres et quantité initiale en
  mode simple. L'enregistrement est confirmé par Supabase avant d'annoncer la
  réussite. En inventaire/cycles, le stock débute dans le module concerné.
- Correction par le propriétaire du nom, de l'unité, du code-barres et du seuil
  d'alerte d'un produit, dans tous les modes. En mode simple, il peut aussi
  corriger les prix ; la fonction serveur écrit `product_prices` atomiquement.
- Recherche locale dans le catalogue chargé et état vide indiquant l'action
  à effectuer.
- Interface adaptable au téléphone et à l'ordinateur. Internet est requis.
- Accueil : produits, articles et ruptures du catalogue ; pour les boutiques
  hors inventaire périodique, nombre et total des ventes du jour déjà
  synchronisées. Ces chiffres ne représentent pas le solde de caisse.
- En mode simple, accueil et stock montrent au propriétaire la valeur du stock
  calculée au prix d'achat, séparée des ventes et de la caisse. Le web ne
  demande pas le prix d'achat pour une session employé ; le catalogue est
  paginé pour éviter un montant incomplet au-delà de 1 000 produits. En modes
  Inventaire et Cycles, la fiche ne montre pas la quantité de `products` : le
  stock se lit dans le module concerné.
- Journal en lecture seule : ventes et mouvements de caisse du jour choisi,
  avec détails de vente sans prix d'achat ni bénéfice. Chaque lecture est
  filtrée par boutique. Une vente faite hors ligne sur Android y apparaît
  après synchronisation. Le journal n'est pas présenté en inventaire
  périodique, dont le fonctionnement diffère. Le calendrier ouvre directement
  une ancienne journée, utile pour vérifier les ventes copiées.
- La création de produits web est réservée au rôle propriétaire, comme sur
  Android ; le vendeur conserve la consultation du stock.
- Navigation par réglages de boutique : en mode simple, accueil/journal/caisse/stock/bilan ;
  en inventaire périodique, inventaire à la place du journal ; en cycles,
  onglet propriétaire ; commandes comme onglet additionnel. La navigation
  ordinateur et téléphone utilise la même liste de destinations.
- Inventaire périodique : vues des recettes et comptages récents ; formulaire
  de création/correction d'une recette avec le même UUID déterministe
  « boutique + date » qu'Android. Parcours à valider sur une boutique staging
  réellement configurée dans ce mode.
- Cycles : vue des arrivages récents et de leur état, sans exposer les coûts
  dans l'interface. Commandes : vue des dossiers et de leur solde calculé
  par la vue serveur, et formulaire de demande (sans prix pour l'employé).
  Les UUID fixes permettent de reprendre une création interrompue sans créer
  un second dossier.
- Commandes : le propriétaire peut fixer ou corriger le prix d'un dossier
  non terminé. Le contrôle serveur empêche de descendre sous les paiements
  déjà encaissés ; la modification d'un dossier sans prix le confirme.

## À réaliser avant une bêta web utilisable comme Android

| Domaine | Opérations encore absentes du web |
|---|---|
| Commun | Validation photo/scan sur Safari iPhone |
| Simple | Validation du parcours complet dans un navigateur connecté, puis sur un vrai téléphone |
| Cycles | Gérer unités, arrivages, pertes, vente par unité et rapport |
| Inventaire | Comptage à l'aveugle, pertes, transferts et rapport de période |
| Commandes | Payer/rembourser, suivre la réalisation, livrer, bilan |

Les écritures qui touchent ensemble plusieurs tables (vente + lignes + stock,
paiement de commande + caisse, cycle + stock) demandent une transaction/RPC
testée sur staging avant l'ouverture sur le web. La base liée localement au
CLI est celle des clients : ne jamais y pousser ces migrations par défaut.

Les prochaines vérifications portent sur le parcours connecté du mode simple
(web → Android et Android → web), les rôles propriétaire/vendeur, les photos et
le scan sur Safari iPhone, puis la coupure réseau. Les autres modes restent des
chantiers séparés. La sécurité staging (prix d'achat accessibles aux vendeurs
par l'API, photos publiques) doit être traitée avant une ouverture au public.

## Vérifications du 28 octobre 2026

- Build Flutter Web réussi ; affichage de la connexion et de l'inscription
  vérifié dans Chrome en format ordinateur et téléphone étroit.
- Compte et boutique entièrement fictifs créés sur staging via le navigateur ;
  déconnexion, reconnexion et relecture de cette boutique réussies.
- Pages légales copiées dans `build/web/legal/` et accessibles en HTTP local.
- `flutter test --no-pub` : 210 tests passés ; analyse globale sans erreur
  bloquante. Le parcours sur Safari iPhone et la comparaison web ↔ Android
  restent à effectuer.

## Vérifications du 29 octobre 2026

- Création d'un produit fictif dans la boutique fictive staging via Chrome :
  ajout confirmé, prix de vente et unité relus depuis Supabase dans le stock.
- Formulaire et écran vide vérifiés sur un format téléphone étroit. La lecture
  du produit sur l'APK Android staging reste à vérifier sur un vrai téléphone.
- Après le retour du Wi-Fi sur le téléphone, la connexion a fonctionné :
  l'échec « CORS request did not succeed » observé pendant la coupure ne
  prouve pas une mauvaise configuration CORS Supabase.
- Base visuelle web dédiée (`lib/web/web_theme.dart`) : palette, police Noto
  Sans, connexion, navigation du stock, indicateurs, catalogue et entête
  téléphone réorganisés. Captures vérifiées en 1440 px et 390 px avec un
  compte fictif staging. La parité fonctionnelle Android/web reste à faire.
- Le build staging désactive le service worker Flutter ; le bootstrap retire
  les anciennes inscriptions pour éviter une ancienne interface en cache.
  Un ancien navigateur peut nécessiter un rechargement forcé la première fois.
- Analyse globale sans erreur bloquante, 210 tests passés, build web réussi.
- Le serveur local HTTP sert uniquement aux essais fictifs. Il déclenche un
  avertissement navigateur pour les mots de passe ; prévoir une URL HTTPS
  avant tout test avec un compte ou des données réelles.
- Accueil et journal relus sur la boutique fictive staging : aucune vente
  enregistrée ce jour-là. Accueil capturé en 1440 px et 390 px. Le clic
  interactif sur le journal reste à vérifier : la revue automatique a refusé
  l'ouverture d'un port de débogage Chrome sur un profil authentifié.
- À trancher avant usage multi-pays : le « jour » est actuellement calculé
  avec l'heure locale de l'appareil, comme l'Android. Une boutique au Cameroun
  consultée depuis la France peut changer de jour à une heure différente en
  été ; il faudra une zone horaire par boutique pour des bilans cohérents.
- Les pages des modes et la création de demande n'ont pas encore été vérifiées
  en navigation réelle avec des boutiques fictives configurées dans chacun
  des modes. Le compte fictif utilisé pour les captures est en mode simple.
- Une demande web crée le client puis le dossier avec des identifiants fixes.
  Si la deuxième écriture échoue et que l'utilisateur ferme le formulaire,
  une fiche client sans dossier peut rester sur staging. Une transaction RPC
  sera nécessaire avant d'utiliser ce flux avec de vraies données.
- 215 tests passés (dont les combinaisons d'onglets simple/inventaire/cycles/
  commandes, rôle propriétaire/employé et cinq onglets sur petit écran) ; analyse globale sans erreur
  bloquante ; build web staging réussi. Le schéma staging ne peut pas être
  inspecté anonymement par REST (HTTP 401). Aucune écriture sur la base des
  clients n'a été effectuée pendant ce chantier web.

## Vérifications du 6 novembre 2026

- Correction de fiche produit ajoutée au stock web pour le propriétaire, en
  mode simple, cycles et inventaire. Les champs de prix et de stock ne figurent
  pas dans la requête de mise à jour.
- Analyse Flutter sans erreur bloquante, 215 tests passés, build staging web
  réussi. Le clic et l'enregistrement dans le nouveau formulaire restent à
  vérifier manuellement sur staging.
- Trois boutiques de test sur un même compte : inventaire périodique (copie de
  Gildas), simple (copie de Cédric Telecom), commandes (copie de
  aislynnconcept). Le script `scripts/copier_donnees_demo_staging.py` interroge
  la production en SELECT puis importe sur staging, en remplaçant noms et
  contacts clients, descriptions de commandes, notes libres, références de
  paiement, photos et identifiants des acteurs. Les produits, prix, quantités,
  dates et opérations métier sont conservés.
- Contrôle après copie : Gildas 399 produits, 308 comptages, 422 achats et 93
  transferts ; Cédric 56 produits et 12 ventes ; aislynnconcept 109 produits,
  18 ventes, 7 commandes et 3 paiements. Les transferts pointent aussi vers
  cinq boutiques de référence sans propriétaire ni accès par le compte de
  test : celui-ci voit exactement les trois boutiques demandées. Aucun contact
  client n'est présent dans les sept fiches copiées.
- Le serveur web local du port 8765 écoute seulement `127.0.0.1` après cette
  copie. L'ancienne adresse HTTP du Wi-Fi est fermée. Une URL HTTPS est requise
  avant un essai depuis un autre appareil ou avec des données réelles.
- Photos publiques copiées de production vers le bucket Storage **staging** :
  156 photos reliées aux produits fictifs (56/56 chez Cédric, 100/109 chez
  aislynnconcept ; les neuf autres n'avaient pas de photo source). Les 21
  transferts initialement refusés ont réussi à la reprise. Une URL d'image
  staging répond en HTTPS avec HTTP 200 et le type `image/jpeg`.
- La fiche produit web affiche maintenant la photo dans un grand cadre placé
  avant les informations ; une vignette apparaît dans les listes ordinateur et
  téléphone. Analyse Flutter sans erreur bloquante, 215 tests passés et build
  staging web réussi. L'ouverture visuelle de la fiche reste à contrôler dans
  un navigateur connecté.
- La valeur du stock à l'achat du mode simple est maintenant réservée au
  propriétaire dans l'accueil et le catalogue web. Elle n'est pas le solde de
  caisse. Les prix
  d'achat restent techniquement accessibles par l'API aux employés tant que
  la correction RLS prévue sur staging n'a pas été appliquée et validée.

## Avancement du mode simple au 13 novembre 2026

- Le stock web affiche le prix de vente et l'unité facultative. Le propriétaire
  peut créer un produit, modifier ses prix avec historique atomique, ajouter du
  stock, archiver puis restaurer un produit, scanner un code, prendre une photo ou la choisir dans la
  galerie. Le formulaire de création peut demander une photo immédiatement
  après l'enregistrement. Le traitement réduit l'image avant l'envoi.
- L'import/export CSV du mode simple reprend les sept colonnes du modèle Android.
  Le fichier est contrôlé entièrement avant l'envoi (100 produits maximum,
  1 Mo). Les produits sont créés en un seul INSERT : un refus annule le lot.
  Les identifiants restent identiques lors d'une nouvelle tentative pour
  empêcher les doublons silencieux après une réponse réseau perdue.
- Le propriétaire du mode simple a un écran Employés : liste des accès,
  création d'un vendeur par la fonction serveur existante `creer-vendeur`, et
  retrait de son accès. Cette fonction a été déployée **sur staging seulement**.
  Le parcours de création dans un navigateur authentifié reste à valider.
- Le compte connecté peut changer son propre mot de passe depuis le menu web.
  Comme sur Android, le formulaire vérifie l'ancien mot de passe avant la
  modification et retire l'obligation de mot de passe provisoire.
- Le journal et le bilan web utilisent désormais les bornes du jour et du
  mois en heure du Cameroun (UTC+1), même si le navigateur est ouvert depuis
  la France. La clôture serveur utilise `Africa/Douala`.
- La vente web du mode simple accepte plusieurs lignes et un prix de vente par
  ligne. La photo du produit choisi apparaît au-dessus de la quantité et du
  prix. La fonction SQL `web_create_simple_sale` écrit vente, lignes et stock
  dans une transaction et réutilise le même UUID si la réponse réseau se perd.
  Les fonctions SQL web ont été appliquées **seulement sur staging**.
- Une page Caisse calcule le solde continu depuis la dernière clôture, montre
  les entrées et sorties et permet le solde initial, les sorties et la clôture
  par comptage réel. La fonction SQL calcule et conserve l'écart dans la même
  transaction ; un second appel avec le même identifiant n'ajoute pas de ligne.
  Une journée rouverte sur Android peut être reclôturée sur le web avec le
  même identifiant ; sa note précédente reste conservée.
  Le bilan
  mensuel distingue chiffre d'affaires, marge brute, dépenses et déplacements
  d'argent. Un résumé PDF de ces chiffres peut être imprimé depuis le web.
  Les données viennent du serveur et exigent une connexion.
- Reste à faire pour annoncer la parité Android du mode simple : rapport PDF
  détaillé, paramètres, et validation du parcours complet dans un navigateur
  connecté et sur un vrai téléphone. Les ajouts de photo via iPhone/Safari et
  le passage Android ↔ web doivent être testés manuellement.
- Les écritures et les photos restent dans le projet Supabase de test. La
  production n'a pas reçu ces fonctions SQL et n'a pas été modifiée.
- La fonction de clôture a été vérifiée sur staging dans une transaction
  annulée : 12 000 FCFA de vente, 100 FCFA de dépense, 3 000 FCFA de marge,
  2 900 FCFA de bénéfice, un écart calculé et un seul enregistrement après
  répétition du même appel. Le parcours écran sur navigateur reste à tester.
- Reclôture d'une journée rouverte sur Android vérifiée séparément sur staging
  dans une transaction annulée, avec conservation de la note précédente.
- Archivage puis restauration d'un produit test validés avec le rôle
  propriétaire dans une transaction annulée sur staging.

## Parité du mode simple au 26 novembre 2026

Les quatre écarts qui restaient entre le web et le téléphone en mode simple
sont comblés. Le périmètre s'arrête là : cycles, inventaire périodique et
commandes restent des chantiers séparés.

- **Réglages de la boutique** (`web_shop_settings.dart`), réservés au
  propriétaire : vente par unités, inventaire périodique, commandes avec
  acompte. L'exclusion inventaire/commandes est refusée à l'écriture, pas
  seulement grisée dans l'interface. Les **quatre** réglages sont lus puis
  réécrits ensemble : l'enregistrement est un upsert, et une colonne absente
  du message reprend sa valeur par défaut côté serveur. La lecture existante
  de `web_app.dart` n'en prenait que trois — réécrire sans lire
  `multi_point_enabled` aurait éteint le multi-point d'une boutique qui
  n'avait rien demandé. Le provider Android porte le même avertissement.
- **Historique d'audit** (`web_activity_log.dart`), réservé au propriétaire :
  ventes, caisse, stock et clôtures fusionnés et triés. Deux différences
  assumées avec l'Android, qui lit la base locale : seul ce qui est
  synchronisé apparaît, et chaque requête porte le `shop_id` actif.
- **Historique des clôtures** dans la page Caisse. Elle n'en chargeait qu'une,
  la dernière, qui sert de borne au solde continu — or c'est l'historique
  qu'on vient relire quand un écart est contesté. Une seule requête sert
  maintenant aux deux usages.
- **Bilan** : ventes par semaine, écarts de caisse et détail par jour, aux
  mêmes tranches que l'Android (1-7, 8-14, 15-21, 22-fin). Les calculs vivent
  dans `web_bilan_detail.dart` en fonctions pures, partagées par l'écran et le
  PDF : dupliqués, les deux auraient fini par afficher deux totaux pour le
  même mois.

Un trou de sécurité trouvé en vérifiant la parité, et comblé :

- Le web **effaçait** le marqueur `must_change_password` quand on changeait son
  mot de passe, mais ne le **vérifiait jamais**. Un vendeur pouvait donc
  travailler indéfiniment avec le mot de passe provisoire que son patron lui a
  attribué — donc que son patron connaît. Celui-ci pouvait ouvrir une session
  à son nom, et l'historique d'audit attribuerait ces gestes « à la vendeuse ».
  Le web impose maintenant le changement avant tout accès, comme
  `routeImposee()` sur Android, et ne charge aucune donnée de boutique avant.
  Le prédicat est sorti de l'écran pour être testable : c'est la seule
  barrière du web. La déconnexion reste la seule autre sortie, sinon un
  vendeur qui a oublié son mot de passe provisoire serait enfermé.

Deux corrections d'honnêteté des chiffres, trouvées en écrivant ces écrans :

- Le PDF imprimait « Espèces comptées : 0 FCFA, Écart : 0 FCFA » pour une
  journée **dont le tiroir n'a jamais été compté** : `entier(null)` valait 0.
  Ça se lit comme une caisse vérifiée et juste. C'est un tiret désormais, et
  le document dit ce que le tiret signifie.
- Le bilan annonce les journées qui ont des ventes mais aucune clôture, comme
  l'Android. Leurs ventes sont réelles et comptées ; le tiroir, lui, n'a pas
  été vérifié ces jours-là.

Vérifications effectuées : **250 tests passés** (32 nouveaux sur les tranches
hebdomadaires, les écarts de caisse, les journées non clôturées, la réécriture
complète des quatre réglages, l'exclusion des modules, la fusion du journal
d'audit et la garde du mot de passe provisoire) ; analyse sans erreur ni
avertissement ; build web compilé.

Ce qui n'est **pas** vérifié, et doit l'être avant d'annoncer la parité :
le parcours cliqué dans un navigateur connecté à staging, et sur un vrai
téléphone. Le build a été compilé avec une clé de remplacement — la CLI
Supabase n'est pas installée sur ce poste, donc `construire_staging_web.sh`
n'a pas pu récupérer la clé publique de staging. Aucune commande Supabase n'a
été lancée, ni sur staging ni sur la production.
