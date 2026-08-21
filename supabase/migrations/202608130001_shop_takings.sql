-- Module B — recette journalière par boutique.
-- Une nouvelle saisie pour la même journée corrige la valeur existante au
-- lieu de créer un doublon.

create table if not exists public.shop_takings (
  id uuid primary key,
  shop_id uuid not null references public.shops(id) on delete cascade,
  date date not null,
  amount numeric not null check (amount >= 0),
  created_at timestamptz not null default now(),
  unique (shop_id, date)
);

alter table public.shop_takings enable row level security;

drop policy if exists shoptrack_shop_takings_members
  on public.shop_takings;
create policy shoptrack_shop_takings_members
on public.shop_takings
for all to authenticated
using (public.is_shop_member(shop_id))
with check (public.is_shop_member(shop_id));
