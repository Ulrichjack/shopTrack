-- Activité du lundi 00:00 au lundi suivant, heure du Cameroun.
-- SELECT uniquement ; aucune donnée n'est créée ou modifiée.
-- Une connexion n'est pas une preuve d'utilisation continue ; un utilisateur
-- déjà connecté peut utiliser l'app sans changer auth.users.last_sign_in_at.
-- Les gestes hors ligne n'apparaissent ici qu'après leur synchronisation.
with bornes as (
  select
    date_trunc('week', now() at time zone 'Africa/Douala')
      at time zone 'Africa/Douala' as debut,
    (date_trunc('week', now() at time zone 'Africa/Douala') + interval '7 days')
      at time zone 'Africa/Douala' as fin
),
gestes as (
  select s.user_id, s.created_at as date_geste, 'vente' as nature
  from public.sales s cross join bornes b
  where s.created_at >= b.debut and s.created_at < b.fin
  union all
  select c.user_id, c.created_at, 'caisse'
  from public.cash_movements c cross join bornes b
  where c.created_at >= b.debut and c.created_at < b.fin
  union all
  select d.user_id, coalesce(d.closed_at, d.created_at), 'cloture'
  from public.daily_closings d cross join bornes b
  where coalesce(d.closed_at, d.created_at) >= b.debut
    and coalesce(d.closed_at, d.created_at) < b.fin
  union all
  select c.created_by, c.created_at, 'client'
  from public.clients c cross join bornes b
  where c.created_at >= b.debut and c.created_at < b.fin
  union all
  select d.created_by, d.created_at, 'commande'
  from public.dossiers_commandes d cross join bornes b
  where d.created_at >= b.debut and d.created_at < b.fin
  union all
  select p.created_by, p.created_at, 'paiement'
  from public.paiements_commandes p cross join bornes b
  where p.created_at >= b.debut and p.created_at < b.fin
  union all
  select t.created_by, t.created_at, 'transfert'
  from public.stock_transfers t cross join bornes b
  where t.created_at >= b.debut and t.created_at < b.fin
  union all
  select s.owner_id, s.created_at, 'boutique'
  from public.shops s cross join bornes b
  where s.created_at >= b.debut and s.created_at < b.fin
),
par_compte as (
  select
    user_id,
    count(*) filter (where nature = 'vente') as ventes,
    count(*) filter (where nature = 'caisse') as caisse,
    count(*) filter (where nature = 'cloture') as clotures,
    count(*) filter (where nature = 'client') as clients,
    count(*) filter (where nature = 'commande') as commandes,
    count(*) filter (where nature = 'paiement') as paiements,
    count(*) filter (where nature = 'transfert') as transferts,
    count(*) filter (where nature = 'boutique') as boutiques_creees,
    max(date_geste) as dernier_geste
  from gestes
  where user_id is not null
  group by user_id
),
liens_boutiques as (
  select user_id, shop_id, role from public.shop_members
  union
  select owner_id, id, 'owner' from public.shops where owner_id is not null
),
boutiques_par_compte as (
  select l.user_id,
    string_agg(distinct s.name || ' (' || l.role || ')', ', ') as boutiques
  from liens_boutiques l
  join public.shops s on s.id = l.shop_id
  group by l.user_id
)
select
  to_char(b.debut at time zone 'Africa/Douala', 'YYYY-MM-DD') as debut_semaine,
  to_char(b.fin at time zone 'Africa/Douala', 'YYYY-MM-DD') as fin_exclue,
  left(u.id::text, 8) as compte_id_court,
  case
    when nullif(u.phone, '') is not null then '***' || right(u.phone, 4)
    when u.email like '%@shoptrack.cm'
      then '***' || right(split_part(u.email, '@', 1), 4)
    when u.email is not null
      then left(split_part(u.email, '@', 1), 2) || '***@' || split_part(u.email, '@', 2)
    else '(sans identifiant)'
  end as compte_masque,
  coalesce(bp.boutiques, '(aucune boutique liee)') as boutiques,
  case
    when pc.user_id is not null then 'action enregistree'
    when u.last_sign_in_at >= b.debut and u.last_sign_in_at < b.fin
      then 'connexion seulement'
    else 'nouveau compte seulement'
  end as preuve,
  coalesce(pc.ventes, 0) as ventes,
  coalesce(pc.caisse, 0) as caisse,
  coalesce(pc.clotures, 0) as clotures,
  coalesce(pc.clients, 0) as clients,
  coalesce(pc.commandes, 0) as commandes,
  coalesce(pc.paiements, 0) as paiements,
  coalesce(pc.transferts, 0) as transferts,
  coalesce(pc.boutiques_creees, 0) as boutiques_creees,
  to_char(pc.dernier_geste at time zone 'Africa/Douala', 'YYYY-MM-DD HH24:MI') as dernier_geste_cm,
  case when u.last_sign_in_at >= b.debut and u.last_sign_in_at < b.fin
    then to_char(u.last_sign_in_at at time zone 'Africa/Douala', 'YYYY-MM-DD HH24:MI')
  end as connexion_cm,
  case when u.created_at >= b.debut and u.created_at < b.fin
    then to_char(u.created_at at time zone 'Africa/Douala', 'YYYY-MM-DD HH24:MI')
  end as inscription_cm
from auth.users u
cross join bornes b
left join par_compte pc on pc.user_id = u.id
left join boutiques_par_compte bp on bp.user_id = u.id
where pc.user_id is not null
   or (u.last_sign_in_at >= b.debut and u.last_sign_in_at < b.fin)
   or (u.created_at >= b.debut and u.created_at < b.fin)
order by pc.dernier_geste desc nulls last,
  u.last_sign_in_at desc nulls last,
  u.created_at desc;
