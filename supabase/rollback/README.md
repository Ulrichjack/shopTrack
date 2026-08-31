# Retours arrière

Ces fichiers ne sont **pas** des migrations. Ils sont hors de
`supabase/migrations/` exprès, pour que `supabase db push` ne les emporte
jamais. On les colle à la main dans l'éditeur SQL de Supabase, et seulement
pour défaire une migration qui casse la production.

Chacun est **généré depuis la base** (`pg_policies`, `pg_get_functiondef`)
avant l'application de la migration qu'il annule — jamais écrit de mémoire.
Une politique restaurée à une parenthèse près rouvrirait ou fermerait plus que
prévu, sans que rien ne le signale.

| Fichier | Annule |
|---|---|
| `202608270001_owner_seller_rls_ROLLBACK.sql` | La séparation propriétaire/vendeur : restaure les 17 politiques « tout membre peut tout faire » et la version de `apply_stock_movement` sans `security definer` |
