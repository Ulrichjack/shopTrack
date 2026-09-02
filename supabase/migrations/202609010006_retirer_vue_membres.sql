-- Retirer la vue `membres_boutique`, posée quelques heures plus tôt.
--
-- Elle devait nommer les vendeuses par leur téléphone dans le journal
-- d'activité. Elle a vidé l'écran des employés : sa lecture échouait, et
-- l'échec était avalé par un `catch` qui rend une liste vide.
--
-- La leçon dépasse cette vue, et mérite d'être gardée :
--
--   un `catch` qui rend une liste vide transforme une PANNE en ÉCRAN VIDE.
--   Et un écran vide ne se lit pas comme une erreur — il se lit comme
--   « il n'y a personne ». C'est le pire des deux mondes : le bug est
--   invisible ET il ment.
--
-- Le journal s'en tient au rôle : « par la vendeuse ». Ça suffit tant qu'il n'y
-- a qu'une employée, ce qui est le cas de toutes les boutiques d'aujourd'hui.
-- Le jour où il en faudra plus, on repartira d'ici — en testant l'écran des
-- employés avant de livrer, cette fois.

drop view if exists public.membres_boutique;
