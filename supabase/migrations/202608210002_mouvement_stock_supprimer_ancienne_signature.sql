-- Supprimer l'ancienne signature de `apply_stock_movement`.
--
-- `create or replace function` ne remplace que si la signature est
-- IDENTIQUE. En ajoutant `p_created_at`, la migration précédente a créé une
-- SECONDE fonction au lieu de remplacer la première. PostgREST s'est retrouvé
-- devant deux candidates et a refusé chaque vente :
--
--   PGRST203 — Could not choose the best candidate function between:
--   apply_stock_movement(..., p_type => text),
--   apply_stock_movement(..., p_type => text, p_created_at => timestamptz)
--
-- Les ventes partaient en file, étaient refusées cinq fois, puis mises de
-- côté — et le téléchargement s'arrêtait avec elles.
--
-- Supprimer l'ancienne est sans risque : `p_created_at` ayant une valeur par
-- défaut, un appel à cinq paramètres — toutes les versions déjà installées de
-- l'app — tombe sur la nouvelle sans rien changer.
drop function if exists public.apply_stock_movement(
  uuid, uuid, uuid, integer, text
);
