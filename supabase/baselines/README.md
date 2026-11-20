# Base initiale pour un projet Supabase de test vide

`202609300001_schema_snapshot.sql` est un instantané du **schéma public seul**
extrait le 30 septembre 2026. Il contient tables, fonctions et politiques de
production telles qu'elles étaient ce jour-là, mais aucun compte ni donnée
commerciale. Il ne remplace pas les migrations historiques du dépôt : celles-ci
commencent après la création des premières tables.

Pour reconstruire un nouveau projet de test, créer un dossier CLI temporaire
distinct du dépôt avec `supabase init --workdir <dossier>`. Copier cet
instantané dans `<dossier>/supabase/migrations/`, puis les migrations de
`supabase/migrations/` postérieures à `202609300001` à tester. Faire un
`supabase db push --project-ref <REF_TEST> --workdir <dossier> --skip-vault
--dry-run` et vérifier la cible avant d'enlever `--dry-run`. Ne jamais utiliser
la référence de production ni `--linked` sans référence explicite.

Ce fichier ne couvre pas Auth, Storage, les buckets ni les Edge Functions.
Tester ces éléments séparément avec des données fictives avant d'utiliser une
version web ou Android connectée à ce projet de test.
