-- L'HEURE de la clôture, et pas seulement son jour.
--
-- Trouvé le 03/09 sur une question toute simple : « clôturer permet encore de
-- recevoir de l'argent en caisse ? » Oui — et cet argent DISPARAISSAIT.
--
--   18h   clôture, elle compte 100 000, l'application enregistre 100 000
--   19h   une cliente verse un acompte de 20 000 → le tiroir contient 120 000
--         le lendemain, l'application repart de 100 000
--
-- Le solde du lendemain part du dernier comptage, puis n'additionne que les
-- mouvements postérieurs à MINUIT. Ce qui arrive entre la clôture et minuit est
-- trop tard pour la journée close et trop tôt pour la suivante : il tombe dans
-- un trou de six heures.
--
-- La cause tient en une ligne : la table ne gardait que `closing_date`, un
-- jour. Impossible de savoir ce qui s'était passé après le comptage.
--
-- ⚠️ CE QU'ON N'A PAS FAIT, ET POURQUOI : bloquer l'encaissement après la
-- clôture. C'est le réflexe, et c'est le piège déjà payé trois fois ce
-- mois-ci — la cliente verse quand même, la vendeuse prend les billets, et
-- l'argent entre sans être noté. On remplacerait un chiffre faux par un
-- manquant inexpliqué, au nom de quelqu'un. Ce qui arrive doit pouvoir être
-- noté.
--
-- Nullable : les clôtures déjà enregistrées n'ont pas d'heure et retombent sur
-- l'ancien calcul. On ne réécrit pas l'histoire — un bilan déjà consulté ne
-- doit pas changer tout seul.

alter table public.daily_closings
  add column if not exists closed_at timestamptz;

comment on column public.daily_closings.closed_at is
  'Instant réel du comptage. Frontière à partir de laquelle l''argent compte pour le lendemain. Nul sur les clôtures antérieures au 03/09/2026.';
