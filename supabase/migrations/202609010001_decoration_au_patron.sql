-- Le prix d'une décoration événementielle appartient à la patronne.
--
-- Réponse de la cliente, 01/09 : les vendeurs fixent les prix des gâteaux, des
-- objets et des formations — mais pas ceux des décorations.
--
-- La raison se comprend en regardant le métier : un gâteau et une formation ont
-- un tarif connu d'avance, une décoration se chiffre au cas par cas (la salle,
-- le nombre d'invités, ce qu'il faut louer). C'est un devis, pas un prix.
--
-- On ne retire donc PAS ce qu'on a ouvert ce matin — fixer un prix reste
-- ouvert au vendeur, parce que la patronne n'est jamais là et qu'une cliente
-- ne peut pas repartir sans savoir ce qu'elle paiera. On excepte une seule
-- catégorie, celle où le prix n'est pas un tarif mais une estimation.

drop policy if exists shoptrack_dossiers_commandes_member_update
  on public.dossiers_commandes;
create policy shoptrack_dossiers_commandes_member_update
on public.dossiers_commandes
for update to authenticated
using (
  public.is_shop_member(shop_id)
  and statut <> 'annulee'
  and categorie <> 'decoration_evenementielle'
)
with check (
  public.is_shop_member(shop_id)
  and statut <> 'annulee'
  and categorie <> 'decoration_evenementielle'
  and motif_annulation is null
  and annule_at is null
  and annule_par is null
);

-- Une commande livrée est finie : plus de remboursement.
--
-- « Il n'y a pas de remboursement quand on a déjà livré. » L'application ne
-- doit donc plus le proposer — ni l'accepter. Le geste reste possible pour la
-- patronne, qui garde `for all` : une exception rarissime ne doit pas devenir
-- impossible, seulement rare.
drop policy if exists shoptrack_paiements_commandes_member_insert
  on public.paiements_commandes;
create policy shoptrack_paiements_commandes_member_insert
on public.paiements_commandes
for insert to authenticated
with check (
  public.is_shop_member(shop_id)
  and created_by = (select auth.uid())
  and exists (
    select 1
    from public.dossiers_commandes d
    where d.id = paiements_commandes.dossier_id
      and d.shop_id = paiements_commandes.shop_id
      and d.statut <> 'annulee'
      -- Encaisser reste permis après livraison : la cliente peut emporter sa
      -- commande en devant encore de l'argent, et refuser d'enregistrer une
      -- entrée ferait apparaître un surplus inexpliqué au comptage du soir.
      -- Seul le remboursement se ferme.
      and (
        type_mouvement = 'paiement'
        or d.statut <> 'terminee'
      )
  )
);
