-- ShopTrack : premier contrôle en lecture seule dans le SQL Editor Supabase.
-- À exécuter par l'administrateur du projet ; ne modifie aucune donnée.
-- Les résultats décrivent l'instance distante, pas les migrations locales.
-- Ne pas publier les résultats bruts si des noms internes y figurent.

-- 1. Tables exposées : RLS et nombre de politiques.
select
  n.nspname as schema_name,
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  count(p.policyname) as policy_count,
  has_table_privilege('anon', c.oid, 'SELECT') as anon_can_select,
  has_table_privilege('authenticated', c.oid, 'SELECT') as authenticated_can_select
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
left join pg_policies p
  on p.schemaname = n.nspname and p.tablename = c.relname
where n.nspname = 'public' and c.relkind in ('r', 'p')
group by n.nspname, c.relname, c.relrowsecurity, c.oid
order by c.relname;

-- 2. Inventaire des politiques des tables applicatives et du stockage.
--    La présence d'une policy ne prouve pas qu'elle isole les boutiques :
--    relire ses conditions et effectuer des tests avec deux vrais comptes.
select
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
   or (schemaname = 'storage' and tablename = 'objects')
order by schemaname, tablename, policyname;

-- 3. Fonctions privilégiées : leur rôle EXECUTE et leur search_path.
--    Une fonction SECURITY DEFINER n'est pas forcément vulnérable ;
--    ses contrôles d'autorisation doivent être relus fonction par fonction.
select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as arguments,
  p.prosecdef as security_definer,
  p.proconfig as configuration,
  has_function_privilege('anon', p.oid, 'EXECUTE') as anon_can_execute,
  has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_can_execute
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.prosecdef
order by p.proname, arguments;

-- 4. Visibilité des buckets. Les règles d'accès aux objets doivent être
--    vérifiées séparément dans storage.objects et avec de vrais comptes test.
select id, public
from storage.buckets
order by id;
