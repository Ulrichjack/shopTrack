#!/usr/bin/env bash
# Vérifier une boutique DEPUIS LE SERVEUR, et non depuis le téléphone.
#
# POURQUOI CE SCRIPT : `emu.sh commandes` lit la base locale par `run-as`, ce
# qu'un build release interdit — et c'est le release qu'on met entre les mains
# d'une cliente. Tester le vrai produit coûtait donc toute visibilité.
#
# Ici on lit Supabase. La contrepartie est réelle et il faut la connaître :
# HORS LIGNE, LE SERVEUR NE SAIT RIEN. Ces chiffres ne valent qu'après une
# synchronisation réussie — donc après `emu.sh fin`. Pendant la semaine
# simulée, seuls les logs et l'écran disent quelque chose.
#
#   ./scripts/verifier.sh C_Semaine
set -euo pipefail

BOUTIQUE="${1:-}"
[ -n "$BOUTIQUE" ] || { echo "usage : $0 <nom de la boutique>"; exit 1; }

q() { supabase db query --linked "$1" -o csv 2>/dev/null | tail -n +2; }

echo "═══ $BOUTIQUE ═══"
echo
echo "— COMMANDES —"
q "select c.nom, d.categorie, d.statut, coalesce(d.montant_accepte::text,'—') as prix,
          coalesce(d.cout_matiere::text,'—') as cout,
          coalesce(to_char(d.livree_at,'DD/MM'),'—') as livree,
          coalesce((select sum(case when p.type_mouvement='paiement' then p.montant else -p.montant end)
                    from paiements_commandes p where p.dossier_id = d.id), 0) as encaisse
     from dossiers_commandes d
     join shops s on s.id = d.shop_id
     left join clients c on c.id = d.client_id
    where s.name = '$BOUTIQUE'
    order by d.created_at;" | column -t -s,

echo
echo "— CAISSE —"
q "select to_char(m.created_at,'DD/MM') as jour, m.type,
          coalesce(m.category,'—') as motif, m.amount, coalesce(m.note,'—') as note
     from cash_movements m join shops s on s.id = m.shop_id
    where s.name = '$BOUTIQUE' order by m.created_at;" | column -t -s,

echo
echo "— CLÔTURES —"
q "select to_char(c.closing_date,'DD/MM') as jour, c.total_sales as ventes,
          c.total_withdrawals as sorties, c.calculated_cash as calculee,
          coalesce(c.physical_cash::text,'—') as comptee,
          coalesce(c.cash_gap::text,'—') as ecart
     from daily_closings c join shops s on s.id = c.shop_id
    where s.name = '$BOUTIQUE' order by c.closing_date;" | column -t -s,

echo
echo "— CONTRÔLE : espèces des commandes vs lignes de caisse —"
q "select
     (select coalesce(sum(case when p.type_mouvement='paiement' then p.montant else -p.montant end),0)
        from paiements_commandes p join shops s on s.id = p.shop_id
       where s.name = '$BOUTIQUE' and p.mode_paiement = 'especes') as commandes_especes,
     (select coalesce(sum(case when m.type='incoming' then m.amount else -m.amount end),0)
        from cash_movements m join shops s on s.id = m.shop_id
       where s.name = '$BOUTIQUE'
         and m.category in ('Acompte commande','Remboursement commande')) as lignes_caisse;" | column -t -s,
echo "  (les deux nombres doivent être identiques)"

echo
echo "— QUI A FAIT QUOI —"
q "select substr(m.user_id::text,1,8) as compte,
          (select role from shop_members sm where sm.user_id = m.user_id and sm.shop_id = m.shop_id) as role,
          count(*) as mouvements
     from cash_movements m join shops s on s.id = m.shop_id
    where s.name = '$BOUTIQUE' group by 1,2 order by 3 desc;" | column -t -s,
