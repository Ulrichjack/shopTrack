# Ce que je dois savoir expliquer sur ShopTrack

> Une question par zone. Pas un planning : une liste de dettes.
> Je barre une ligne le jour où je sais y répondre **sans ouvrir le fichier**.
>
> Règle : je réponds à voix haute d'abord, j'écris ma réponse, PUIS je fais
> corriger. Si je lis le code avant de répondre, la ligne ne compte pas.

## Flutter — les bases (déjà au plan du 8 au 11)

- [ ] Que se passe-t-il entre `flutter run` et le premier écran ?
- [ ] Pourquoi Flutter reconstruit un widget, et lequel exactement ?
- [ ] `ref.watch` et `ref.read` : si je les échange, qu'est-ce qui casse ?
- [ ] Que voit l'utilisateur pendant un chargement, et en cas d'échec ?

## La synchronisation — le cœur, et ce qu'on ne devine pas

- [ ] Pourquoi le téléphone écrit-il en local AVANT d'envoyer au serveur ?
- [ ] `processQueue()` puis `pullDataFromSupabase()` : pourquoi cet ordre, et
      que se passe-t-il si on l'inverse ?
- [ ] Qu'est-ce que `tablesTirees`, et que se passe-t-il si j'oublie d'y
      déclarer une colonne que je viens d'ajouter ?
- [ ] Une opération refusée par le serveur : pourquoi ne gèle-t-elle pas toute
      la file ? Qu'est-ce qu'une « portée » ?
- [ ] Pourquoi une panne réseau n'est-elle PAS traitée comme un refus ?

## La caisse — là où une erreur coûte de l'argent

- [ ] Pourquoi un acompte encaissé en espèces doit-il écrire une ligne dans
      `cash_movements`, alors qu'il est déjà dans `paiements_commandes` ?
- [ ] Pourquoi le Mobile Money n'entre-t-il pas dans la caisse au moment du
      paiement ?
- [ ] Pourquoi « Versement banque » ne réduit-il pas le bénéfice, alors que
      « Transport » le réduit ?
- [ ] Pourquoi enregistre-t-on l'HEURE de la clôture et pas seulement le jour ?

## Le serveur — ce qui protège vraiment

- [ ] Pourquoi cacher un bouton ne protège rien ?
- [ ] RLS filtre des lignes, pas des colonnes. Quelle conséquence concrète ça a
      eu sur le prix d'achat visible par un vendeur ?
- [ ] Un `upsert` PostgREST a besoin de quelles politiques, et pourquoi ?
- [ ] Pourquoi le coût d'une commande passe-t-il par un déclencheur et pas par
      une politique RLS ?

## Le module commandes — ce que j'ai vu se construire

- [ ] Pourquoi le solde ne se stocke-t-il JAMAIS ?
- [ ] « Soldée », « livrée », « annulée » : trois états, trois questions
      différentes. Lesquelles ?
- [ ] Pourquoi le bénéfice tombe-t-il le jour de la livraison, et pas le jour
      de l'acompte ?
- [ ] Pourquoi « bénéfice inconnu » et « bénéfice nul » ne s'affichent-ils pas
      pareil ?
