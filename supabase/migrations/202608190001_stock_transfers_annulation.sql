-- Un transfert envoyé par erreur restait engagé pour toujours.
--
-- Aucun moyen de revenir en arrière une fois « Envoyer » touché : le stock
-- avait déjà quitté la boutique expéditrice, et rien ne permettait de le
-- récupérer sans faire l'inverse à la main. Demandé par le patron le
-- 19/08/2026 après avoir buté dessus en testant les transferts.
--
-- Nullable, comme received_at : un transfert non annulé n'a rien à dire ici.

alter table public.stock_transfers
  add column if not exists cancelled_at timestamptz;
