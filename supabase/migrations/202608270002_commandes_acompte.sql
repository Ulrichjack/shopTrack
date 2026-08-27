-- Commandes avec acompte : un seul modèle pour gâteau, objet décoratif,
-- formation et décoration événementielle.
--
-- Trois tables seulement. Les particularités d'une catégorie vivent dans
-- `dossiers_commandes.details`, jamais dans une table par métier.
--
-- INVARIANT FINANCIER : le montant accepté d'un dossier n'est pas une recette.
-- Seules les lignes de `paiements_commandes` représentent de l'argent entré
-- ou remboursé. Le solde est calculé par la vue en fin de migration et n'est
-- stocké dans aucune table.

-- ---------------------------------------------------------------------------
-- 1. Clients de la boutique
-- ---------------------------------------------------------------------------

create table if not exists public.clients (
  id uuid primary key,
  shop_id uuid not null references public.shops(id) on delete cascade,
  nom text not null check (length(trim(nom)) > 0),
  telephone text,
  whatsapp text,
  adresse text,
  note text,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- Permet la FK composite de dossiers_commandes : un dossier ne peut jamais
  -- pointer vers le client d'une autre boutique, même via service_role.
  constraint clients_id_shop_unique unique (id, shop_id)
);

create index if not exists clients_shop_nom_idx
  on public.clients (shop_id, nom);
create index if not exists clients_shop_telephone_idx
  on public.clients (shop_id, telephone)
  where telephone is not null;

alter table public.clients enable row level security;

drop policy if exists shoptrack_clients_owner_all on public.clients;
create policy shoptrack_clients_owner_all
on public.clients
for all to authenticated
using (public.is_shop_owner(shop_id))
with check (public.is_shop_owner(shop_id));

drop policy if exists shoptrack_clients_member_read on public.clients;
create policy shoptrack_clients_member_read
on public.clients
for select to authenticated
using (public.is_shop_member(shop_id));

-- La vendeuse peut créer la fiche nécessaire à sa demande, mais pas réécrire
-- ni supprimer une identité déjà utilisée. Le propriétaire peut la corriger.
drop policy if exists shoptrack_clients_member_insert on public.clients;
create policy shoptrack_clients_member_insert
on public.clients
for insert to authenticated
with check (
  public.is_shop_member(shop_id)
  and created_by = (select auth.uid())
);

-- ---------------------------------------------------------------------------
-- 2. Dossiers de commande
-- ---------------------------------------------------------------------------

create table if not exists public.dossiers_commandes (
  id uuid primary key,
  shop_id uuid not null references public.shops(id) on delete cascade,
  client_id uuid not null,
  categorie text not null check (
    categorie in (
      'gateau',
      'objet_decoratif',
      'formation',
      'decoration_evenementielle'
    )
  ),
  description text not null check (length(trim(description)) > 0),
  details jsonb not null default '{}'::jsonb
    check (jsonb_typeof(details) = 'object'),
  montant_accepte bigint check (montant_accepte >= 0),
  date_prevue timestamptz,
  statut text not null default 'demande' check (
    statut in (
      'demande',
      'devis',
      'confirmee',
      'en_cours',
      'prete',
      'terminee',
      'annulee'
    )
  ),
  motif_annulation text,
  annule_at timestamptz,
  annule_par uuid,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint dossiers_commandes_client_same_shop_fk
    foreign key (client_id, shop_id)
    references public.clients(id, shop_id)
    on delete restrict,
  constraint dossiers_commandes_id_shop_unique unique (id, shop_id),

  -- Une demande peut naître sans prix. Dès qu'elle avance dans le flux, le
  -- propriétaire doit avoir fixé le montant accepté. Une demande sans suite
  -- peut aussi être annulée avant tout devis.
  constraint dossiers_commandes_montant_selon_statut_check check (
    statut in ('demande', 'annulee') or montant_accepte is not null
  ),
  constraint dossiers_commandes_annulation_coherente_check check (
    (statut = 'annulee' and annule_at is not null and annule_par is not null)
    or
    (statut <> 'annulee' and annule_at is null and annule_par is null)
  )
);

create index if not exists dossiers_commandes_shop_statut_date_idx
  on public.dossiers_commandes (shop_id, statut, date_prevue);
create index if not exists dossiers_commandes_client_idx
  on public.dossiers_commandes (client_id, created_at desc);

alter table public.dossiers_commandes enable row level security;

drop policy if exists shoptrack_dossiers_commandes_owner_all
  on public.dossiers_commandes;
create policy shoptrack_dossiers_commandes_owner_all
on public.dossiers_commandes
for all to authenticated
using (public.is_shop_owner(shop_id))
with check (public.is_shop_owner(shop_id));

drop policy if exists shoptrack_dossiers_commandes_member_read
  on public.dossiers_commandes;
create policy shoptrack_dossiers_commandes_member_read
on public.dossiers_commandes
for select to authenticated
using (public.is_shop_member(shop_id));

-- La vendeuse enregistre seulement la demande. Elle ne peut ni choisir le
-- prix, ni la faire naître confirmée, ni préparer une annulation à l'insertion.
drop policy if exists shoptrack_dossiers_commandes_member_insert
  on public.dossiers_commandes;
create policy shoptrack_dossiers_commandes_member_insert
on public.dossiers_commandes
for insert to authenticated
with check (
  public.is_shop_member(shop_id)
  and created_by = (select auth.uid())
  and montant_accepte is null
  and statut = 'demande'
  and motif_annulation is null
  and annule_at is null
  and annule_par is null
);

-- ---------------------------------------------------------------------------
-- 3. Paiements et remboursements
-- ---------------------------------------------------------------------------

create table if not exists public.paiements_commandes (
  id uuid primary key,
  shop_id uuid not null references public.shops(id) on delete cascade,
  dossier_id uuid not null,
  type_mouvement text not null check (
    type_mouvement in ('paiement', 'remboursement')
  ),
  montant bigint not null check (montant > 0),
  mode_paiement text not null check (
    mode_paiement in ('especes', 'mobile_money', 'virement', 'autre')
  ),
  reference_externe text,
  note text,
  effectue_at timestamptz not null default now(),
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now(),

  constraint paiements_commandes_dossier_same_shop_fk
    foreign key (dossier_id, shop_id)
    references public.dossiers_commandes(id, shop_id)
    on delete restrict
);

create index if not exists paiements_commandes_dossier_date_idx
  on public.paiements_commandes (dossier_id, effectue_at);
create index if not exists paiements_commandes_shop_date_idx
  on public.paiements_commandes (shop_id, effectue_at);

alter table public.paiements_commandes enable row level security;

drop policy if exists shoptrack_paiements_commandes_owner_all
  on public.paiements_commandes;
create policy shoptrack_paiements_commandes_owner_all
on public.paiements_commandes
for all to authenticated
using (public.is_shop_owner(shop_id))
with check (public.is_shop_owner(shop_id));

drop policy if exists shoptrack_paiements_commandes_member_read
  on public.paiements_commandes;
create policy shoptrack_paiements_commandes_member_read
on public.paiements_commandes
for select to authenticated
using (public.is_shop_member(shop_id));

-- Append-only pour la vendeuse : elle insère un encaissement mais n'obtient
-- aucune policy UPDATE ou DELETE. Une correction passe par le propriétaire ;
-- un remboursement est toujours une nouvelle ligne de type `remboursement`.
drop policy if exists shoptrack_paiements_commandes_member_insert
  on public.paiements_commandes;
create policy shoptrack_paiements_commandes_member_insert
on public.paiements_commandes
for insert to authenticated
with check (
  public.is_shop_member(shop_id)
  and created_by = (select auth.uid())
  and type_mouvement = 'paiement'
  and exists (
    select 1
    from public.dossiers_commandes
    where dossiers_commandes.id = paiements_commandes.dossier_id
      and dossiers_commandes.shop_id = paiements_commandes.shop_id
      and dossiers_commandes.statut <> 'annulee'
  )
);

-- ---------------------------------------------------------------------------
-- 4. Solde calculé, jamais stocké
-- ---------------------------------------------------------------------------
-- Les montants de remboursement restent positifs dans la table :
--   net encaissé = paiements - remboursements
--   solde        = montant accepté - net encaissé
-- Un dossier sans montant accepté conserve un solde NULL.

create or replace view public.dossiers_commandes_avec_solde
with (security_invoker = true)
as
select
  dossier.*,
  finances.total_paye,
  finances.total_rembourse,
  finances.total_paye - finances.total_rembourse as montant_net_encaisse,
  case
    when dossier.montant_accepte is null then null
    else dossier.montant_accepte
      - (finances.total_paye - finances.total_rembourse)
  end as solde
from public.dossiers_commandes as dossier
cross join lateral (
  select
    coalesce(
      sum(paiement.montant)
        filter (where paiement.type_mouvement = 'paiement'),
      0
    ) as total_paye,
    coalesce(
      sum(paiement.montant)
        filter (where paiement.type_mouvement = 'remboursement'),
      0
    ) as total_rembourse
  from public.paiements_commandes as paiement
  where paiement.dossier_id = dossier.id
) as finances;

revoke all on public.dossiers_commandes_avec_solde from anon;
grant select on public.dossiers_commandes_avec_solde to authenticated;

comment on view public.dossiers_commandes_avec_solde is
  'Le devis ne vaut jamais recette : seuls paiements moins remboursements sont encaissés.';
