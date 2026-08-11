-- Fondation des modules métier optionnels par boutique (voir
-- docs/ARCHITECTURE_MODULES.md et docs/PLAN_MODULES_CLIENTS.md).
-- Une ligne par boutique ; absence de ligne = comportement actuel par défaut
-- (mode simple, vente temps réel) pour ne rien casser pour les boutiques
-- existantes.

create table if not exists public.shop_settings (
  shop_id uuid primary key references public.shops(id) on delete cascade,
  unit_mode text not null default 'simple'
    check (unit_mode in ('simple', 'hierarchical')),
  sale_capture_mode text not null default 'realtime'
    check (sale_capture_mode in ('realtime', 'periodic')),
  multi_point_enabled boolean not null default false,
  updated_at timestamptz not null default now()
);

alter table public.shop_settings enable row level security;

drop policy if exists shoptrack_shop_settings_members
  on public.shop_settings;
create policy shoptrack_shop_settings_members
on public.shop_settings
for all to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));
