-- Ouvrir le prix et le remboursement à la vendeuse.
--
-- Écrit le 31/08, quelques heures après avoir fermé les deux. La raison de les
-- rouvrir est la même que celle qui avait rouvert la sortie de caisse et la
-- clôture, et elle tient en une phrase de la cliente :
--
--   « la patronne n'est jamais là. »
--
-- Une cliente entre, commande un gâteau, demande le prix. Si seule la
-- propriétaire peut le fixer, la vendeuse note la demande et... la cliente
-- repart sans savoir ce qu'elle paiera. Le contrôle qu'on croyait protéger
-- n'existe pas : il empêche seulement de servir.
--
-- Même chose pour le remboursement. Une commande annulée le matin, la cliente
-- devant le comptoir : sans ce droit, la vendeuse rend l'argent du tiroir
-- SANS l'enregistrer — et le soir la caisse accuse un manquant, à son nom.
-- Interdire le geste ne l'empêche pas, ça le rend invisible.
--
-- ⚠️ CE QUI REMPLACE L'INTERDICTION : la traçabilité, déjà en place.
--
-- `dossiers_commandes.created_by` et `paiements_commandes.created_by` portent
-- `auth.uid()` par défaut depuis la création des tables. Chaque prix fixé et
-- chaque remboursement porte donc un nom. C'est l'arbitrage retenu partout
-- ailleurs dans cette application : on trace, on n'empêche pas.
--
-- Ce qui reste fermé au membre, et pourquoi :
--   annuler un dossier   efface une commande d'un bilan déjà consulté
--   supprimer un paiement l'histoire de l'argent ne se réécrit pas

-- 1. Le membre peut mettre à jour un dossier — sauf l'annuler.
drop policy if exists shoptrack_dossiers_commandes_member_update
  on public.dossiers_commandes;
create policy shoptrack_dossiers_commandes_member_update
on public.dossiers_commandes
for update to authenticated
using (public.is_shop_member(shop_id) and statut <> 'annulee')
with check (
  public.is_shop_member(shop_id)
  and statut <> 'annulee'
  and motif_annulation is null
  and annule_at is null
  and annule_par is null
);

-- 2. Le membre peut enregistrer un remboursement.
--
-- Toujours en AJOUTANT une ligne : aucune politique UPDATE ni DELETE ne lui est
-- donnée sur les paiements. Rendre 20 000 F laisse donc deux lignes — l'acompte
-- encaissé et le remboursement — et pas une ligne effacée.
drop policy if exists shoptrack_paiements_commandes_member_insert
  on public.paiements_commandes;
create policy shoptrack_paiements_commandes_member_insert
on public.paiements_commandes
for insert to authenticated
with check (
  public.is_shop_member(shop_id)
  and created_by = (select auth.uid())
  and type_mouvement in ('paiement', 'remboursement')
  and exists (
    select 1
    from public.dossiers_commandes
    where dossiers_commandes.id = paiements_commandes.dossier_id
      and dossiers_commandes.shop_id = paiements_commandes.shop_id
      and dossiers_commandes.statut <> 'annulee'
  )
);
