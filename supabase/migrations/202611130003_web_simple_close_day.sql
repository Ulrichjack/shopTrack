-- Clôture web du mode simple, calculée côté serveur dans la même transaction.
-- Le jour de la boutique est actuellement celui du Cameroun (Africa/Douala).
create or replace function public.web_close_simple_day(
  p_shop_id uuid,
  p_closing_id uuid,
  p_physical_cash numeric,
  p_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  instant timestamptz := clock_timestamp();
  jour date := (clock_timestamp() at time zone 'Africa/Douala')::date;
  debut_jour timestamptz;
  derniere public.daily_closings%rowtype;
  courante public.daily_closings%rowtype;
  origine timestamptz := '-infinity'::timestamptz;
  base numeric := 0;
  checkpoint public.cash_movements%rowtype;
  montant_ventes numeric := 0;
  marge numeric := 0;
  entrees numeric := 0;
  sorties numeric := 0;
  ajustements_sortants numeric := 0;
  depenses numeric := 0;
  caisse_calculee numeric;
begin
  if (select auth.uid()) is null or not public.is_shop_member(p_shop_id) then
    raise exception 'Accès refusé à cette boutique.' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.shop_settings where shop_id = p_shop_id
      and sale_capture_mode = 'realtime' and unit_mode = 'simple'
  ) then
    raise exception 'Clôture réservée au mode simple.' using errcode = '22023';
  end if;
  if p_physical_cash is null or p_physical_cash < 0
      or p_physical_cash <> trunc(p_physical_cash)
      or length(coalesce(p_note, '')) > 500 then
    raise exception 'Montant ou note invalide.' using errcode = '22023';
  end if;

  -- Une journée rouverte sur Android conserve son identifiant et sa note.
  select * into courante from public.daily_closings
  where shop_id = p_shop_id and closing_date = jour for update;
  if found then
    if courante.id <> p_closing_id then
      raise exception 'Utiliser l''identifiant de la journée existante.'
        using errcode = '23505';
    end if;
    if courante.is_closed then return p_closing_id; end if;
  elsif exists (select 1 from public.daily_closings
      where id = p_closing_id) then
    raise exception 'Identifiant de clôture déjà utilisé.' using errcode = '23505';
  end if;
  debut_jour := jour::timestamp at time zone 'Africa/Douala';
  select * into derniere from public.daily_closings
  where shop_id = p_shop_id and is_closed and closing_date < jour
  order by closing_date desc limit 1;
  if found then
    base := coalesce(derniere.physical_cash, derniere.calculated_cash, 0);
    origine := coalesce(
      derniere.closed_at,
      (derniere.closing_date + 1)::timestamp at time zone 'Africa/Douala'
    );
  end if;

  -- Rejouer les événements jusqu'à minuit pour obtenir le fonds d'ouverture.
  select * into checkpoint from public.cash_movements
  where shop_id = p_shop_id and type = 'morning_balance'
    and created_at >= origine and created_at < debut_jour
  order by created_at desc, id desc limit 1;
  if found then
    base := checkpoint.amount;
    origine := checkpoint.created_at;
  elsif derniere.id is null and not exists (
    select 1 from public.cash_movements
    where shop_id = p_shop_id and type = 'morning_balance'
  ) then
    raise exception 'Définir le solde initial avant de clôturer.'
      using errcode = '22023';
  end if;
  select base + coalesce(sum(total_amount), 0) into base
  from public.sales where shop_id = p_shop_id
    and created_at >= origine and created_at < debut_jour;
  select base +
      coalesce(sum(case when type in ('incoming', 'adjustment_in') then amount
                        when type in ('withdrawal', 'adjustment_out') then -amount
                        else 0 end), 0)
    into base
  from public.cash_movements where shop_id = p_shop_id
    and created_at >= origine and created_at < debut_jour;

  -- Un solde saisi ce matin devient le nouveau point de départ de la journée.
  select * into checkpoint from public.cash_movements
  where shop_id = p_shop_id and type = 'morning_balance'
    and created_at >= debut_jour and created_at <= instant
  order by created_at desc, id desc limit 1;
  if found then
    base := checkpoint.amount;
    origine := checkpoint.created_at;
  else
    origine := debut_jour;
  end if;

  select coalesce(sum(total_amount), 0), coalesce(sum(total_profit), 0)
    into montant_ventes, marge
  from public.sales where shop_id = p_shop_id
    and created_at >= origine and created_at <= instant;
  select
    coalesce(sum(case when type in ('incoming', 'adjustment_in') then amount else 0 end), 0),
    coalesce(sum(case when type = 'withdrawal' then amount else 0 end), 0),
    coalesce(sum(case when type = 'adjustment_out' then amount else 0 end), 0),
    coalesce(sum(case when type = 'withdrawal' and
      coalesce(category, '') not in
      ('Versement banque', 'Retrait patron', 'Remise à la patronne',
       'Remboursement commande', 'Entrée depuis un compte')
      then amount else 0 end), 0)
    into entrees, sorties, ajustements_sortants, depenses
  from public.cash_movements where shop_id = p_shop_id
    and created_at >= origine and created_at <= instant;
  caisse_calculee := base + montant_ventes + entrees - sorties - ajustements_sortants;

  if courante.id is null then
    insert into public.daily_closings (
    id, shop_id, user_id, closing_date, morning_balance, total_sales,
    total_withdrawals, calculated_cash, gross_profit, net_profit,
    physical_cash, cash_gap, is_closed, closed_at, note
  ) values (
    p_closing_id, p_shop_id, (select auth.uid()), jour, base, montant_ventes,
    sorties, caisse_calculee, marge, marge - depenses,
    p_physical_cash, p_physical_cash - caisse_calculee, true, instant,
    nullif(btrim(p_note), '')
    );
  else
    update public.daily_closings set
      user_id = (select auth.uid()),
      morning_balance = base,
      total_sales = montant_ventes,
      total_withdrawals = sorties,
      calculated_cash = caisse_calculee,
      gross_profit = marge,
      net_profit = marge - depenses,
      physical_cash = p_physical_cash,
      cash_gap = p_physical_cash - caisse_calculee,
      is_closed = true,
      closed_at = instant,
      note = nullif(concat_ws(E'\n', nullif(btrim(courante.note), ''),
          nullif(btrim(p_note), '')), '')
    where id = p_closing_id and shop_id = p_shop_id;
  end if;
  return p_closing_id;
end;
$$;

revoke all on function public.web_close_simple_day(uuid, uuid, numeric, text)
  from public;
revoke all on function public.web_close_simple_day(uuid, uuid, numeric, text)
  from anon;
grant execute on function public.web_close_simple_day(uuid, uuid, numeric, text)
  to authenticated;
