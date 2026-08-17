# ShopTrack

Application Flutter de gestion de boutique avec cache local Drift et
synchronisation Supabase.

## Préparation

```bash
flutter pub get
flutter test
flutter run
```

## Migration Supabase obligatoire

La synchronisation atomique du stock dépend de la fonction
`apply_stock_movement`. Avant d'installer cette version sur les téléphones,
appliquer, dans cet ordre :

```text
supabase/migrations/202607270001_secure_sync.sql
supabase/migrations/202607280002_stock_sync_and_unique_barcodes.sql
supabase/migrations/202608090001_shop_settings.sql
supabase/migrations/202608090002_module_a_cycles.sql
supabase/migrations/202608130001_shop_takings.sql
supabase/migrations/202608130002_module_b_inventory.sql
supabase/migrations/202608130003_product_unit.sql
supabase/migrations/202608140001_product_prices.sql
supabase/migrations/202608170001_shop_members_owner.sql
```

### Fonctions serveur

```bash
supabase functions deploy creer-vendeur
```

Avec Supabase CLI sur un projet déjà lié :

```bash
supabase db push
```

La migration :

- empêche qu'une vente renvoyée deux fois redécompte le stock ;
- refuse un stock négatif ;
- ajoute l'unicité d'une clôture par boutique et par date ;
- active des politiques RLS limitées aux membres de la boutique.

Vérifier les politiques déjà présentes dans le tableau de bord Supabase avant
la production. Si des clôtures en double existent déjà, les corriger avant de
créer l'index unique.

## Signature Android

Une version `release` n'utilise plus la clé de débogage. Copier
`android/key.properties.example` vers `android/key.properties`, créer un
keystore privé, puis renseigner les quatre valeurs. Ne jamais versionner le
keystore ni `key.properties`.

## Validation avant production

Tester le même APK sur au moins deux téléphones :

1. accepter, refuser puis réactiver la permission caméra ;
2. scanner le QR d'un produit créé sur l'autre téléphone ;
3. vendre le même produit depuis deux téléphones ;
4. effectuer une vente hors ligne, revenir en ligne et vérifier l'écran
   **État de synchronisation** ;
5. clôturer avec un manque puis un surplus et vérifier le bilan et son PDF ;
6. confirmer qu'un vendeur ne peut ouvrir ni le bilan ni l'audit par une route
   directe.

Les sauvegardes JSON sont écrites dans le dossier applicatif
`Documents/ShopTrackBackups`, automatiquement à chaque clôture et manuellement
depuis le profil Patron.
