-- Un transfert ne peut relier que deux boutiques du même propriétaire.
-- La policy précédente utilisait OR : posséder une seule des deux boutiques
-- suffisait pour lire ou modifier une ligne impliquant une boutique tierce.
drop policy if exists shoptrack_stock_transfers_owner_all
  on public.stock_transfers;

create policy shoptrack_stock_transfers_owner_both_sides
on public.stock_transfers
for all to authenticated
using (
  public.is_shop_owner(from_shop_id)
  and public.is_shop_owner(to_shop_id)
)
with check (
  public.is_shop_owner(from_shop_id)
  and public.is_shop_owner(to_shop_id)
);
