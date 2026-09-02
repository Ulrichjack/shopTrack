#!/usr/bin/env bash
# Piloter l'émulateur pendant une simulation sur plusieurs jours.
#
# POURQUOI CE SCRIPT : simuler une semaine demande de déplacer la date du
# téléphone, et les deux sens cassent le réseau —
#
#   • en AVANT  : les jetons sont « émis dans le futur », PostgREST les refuse
#                 (PGRST303). Voir docs/PIEGES_CONNUS.md n°29.
#   • en ARRIÈRE : le certificat TLS de Supabase a une date de début de
#                 validité. Un téléphone qui se croit avant cette date refuse
#                 la connexion (HandshakeException).
#
# D'où la méthode : on coupe le réseau, on simule les journées hors ligne — le
# téléphone empile tout dans sa file — puis on rétablit l'heure et le réseau,
# et l'application envoie la semaine entière d'un coup. Ça teste au passage le
# fonctionnement sans réseau, qui est le cœur de ShopTrack.
#
#   ./scripts/emu.sh hors-ligne     coupe le réseau (à faire en premier)
#   ./scripts/emu.sh jour 23        23 août 2026 (le mois par défaut est août)
#   ./scripts/emu.sh jour 1/9       1er septembre 2026 — pour passer le mois
#   ./scripts/emu.sh jour 2026-09-04   une date complète, si besoin
#   ./scripts/emu.sh etat           date, réseau, file d'attente
#   ./scripts/emu.sh commandes      dossiers, soldes et lien avec la caisse
#   ./scripts/emu.sh fin            rétablit heure et réseau, puis synchronise
set -euo pipefail

ADB=/home/jack/Android/Sdk/platform-tools/adb

# Sans cette vérification, `set -e` faisait sortir le script EN SILENCE quand
# l'émulateur n'était pas là : pas un mot, pas un code d'erreur visible, on
# croyait la commande passée. Un outil qui échoue sans le dire est pire qu'un
# outil qui manque.
exiger_appareil() {
  if ! "$ADB" devices | grep -q "^emulator-.*device$"; then
    echo "❌ aucun émulateur attaché."
    echo "   Lance-le, attends le démarrage complet, puis recommence."
    exit 1
  fi
}
PKG=cm.shoptrack.shoptrack
DB=/data/data/$PKG/app_flutter/shoptrack_local.sqlite

# La boutique active, lue dans les préférences du téléphone.
#
# Sans ce filtre, `commandes` montrait les dossiers de TOUTES les boutiques
# empilés — et on a lu comme un bug d'A_Semaine une commande d'A_Commande.
# C'est le même défaut que le journal de caisse qui mélangeait les boutiques :
# une base locale contient tout, une requête sans `shop_id` ment.
boutique_active() {
  "$ADB" shell run-as $PKG cat /data/data/$PKG/shared_prefs/FlutterSharedPreferences.xml 2>/dev/null \
    | grep -oE 'cached_shop_id">[^<]*' | head -1 | cut -d'>' -f2
}

relancer() {
  "$ADB" shell am force-stop "$PKG"
  sleep 2
  "$ADB" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
  sleep 8
  if "$ADB" shell pidof "$PKG" >/dev/null 2>&1; then
    echo "  application relancée"
  else
    echo "  ⚠️  l'application n'a pas redémarré"
  fi
}

case "${1:-}" in
  hors-ligne)
    exiger_appareil
    "$ADB" root >/dev/null 2>&1 || true
    sleep 1
    "$ADB" shell svc wifi disable
    "$ADB" shell svc data disable
    "$ADB" shell settings put global airplane_mode_on 1
    "$ADB" shell settings put global auto_time 0
    echo "réseau coupé, heure automatique désactivée"
    ;;

  jour)
    [ $# -ge 2 ] || { echo "usage : $0 jour 23   (ou 2026-08-23)"; exit 1; }
    exiger_appareil
    jour="$2"
    # Trois écritures acceptées, de la plus courte à la plus explicite :
    #   26        → 26 août 2026   (le mois par défaut de la simulation)
    #   1/9       → 1er sept. 2026 (pour franchir la bascule de mois)
    #   2026-09-04
    if [[ "$jour" =~ ^([0-9]{1,2})/([0-9]{1,2})$ ]]; then
      jour="2026-$(printf '%02d' "${BASH_REMATCH[2]}")-$(printf '%02d' "${BASH_REMATCH[1]}")"
    elif [[ "$jour" =~ ^[0-9]{1,2}$ ]]; then
      jour="2026-08-$(printf '%02d' "$jour")"
    fi
    if ! "$ADB" shell "date -s '$jour 08:00:00'" >/dev/null 2>&1; then
      echo "❌ impossible de changer la date. L'émulateur répond-il ?"
      exit 1
    fi
    obtenue=$("$ADB" shell date | tr -d '\r')
    echo "date du téléphone : $obtenue"
    # On RELIT la date au lieu de faire confiance : Android refuse parfois le
    # changement sans le dire, et on simulerait alors huit journées au même
    # jour sans jamais s'en apercevoir.
    # Espaces écrasés des deux côtés : Android écrit « Sep  1 » avec deux
    # espaces, `date` en met un. Sans ça, la vérification criait au loup à
    # chaque jour à un chiffre.
    attendue=$(date -d "$jour" '+%b %-d' 2>/dev/null | tr -s ' ')
    if ! echo "$obtenue" | tr -s ' ' | grep -qF "$attendue"; then
      echo "  ⚠️  la date n'a PAS été prise en compte — vérifie avant de saisir."
    fi
    # Rappel utile : hors ligne c'est sans danger, en ligne ça casse.
    if [ "$("$ADB" shell settings get global airplane_mode_on | tr -d '\r')" != "1" ]; then
      echo "  ⚠️  le réseau est ACTIF : avec une date décalée, les requêtes"
      echo "      seront refusées. Lance d'abord : $0 hors-ligne"
    fi
    relancer
    ;;

  etat)
    exiger_appareil
    echo "date      : $("$ADB" shell date | tr -d '\r')"
    echo "mode avion: $("$ADB" shell settings get global airplane_mode_on | tr -d '\r')"
    echo "boutique  : $("$ADB" shell run-as $PKG cat /data/data/$PKG/shared_prefs/FlutterSharedPreferences.xml 2>/dev/null | grep -oE 'cached_shop_name">[^<]*' | cut -d'>' -f2)"
    echo "en attente d'envoi :"
    "$ADB" shell "run-as $PKG sqlite3 $DB \"select count(*) from sync_queue_items;\"" 2>/dev/null \
      | sed 's/^/  /'
    ;;

  commandes)
    exiger_appareil
    # Ce que l'écran devrait montrer, lu directement dans la base du téléphone.
    #
    # Le solde est RECALCULÉ ici comme il l'est dans l'application : s'il
    # divergeait, c'est que quelque chose le stocke quelque part — et c'est
    # justement ce qu'on s'interdit.
    SHOP=$(boutique_active)
    echo "boutique : $("$ADB" shell run-as $PKG cat /data/data/$PKG/shared_prefs/FlutterSharedPreferences.xml 2>/dev/null | grep -oE 'cached_shop_name">[^<]*' | cut -d'>' -f2)"
    echo
    echo "— DOSSIERS —"
    "$ADB" shell "run-as $PKG sqlite3 -header -column $DB \
      \"select substr(d.id,1,8) as id, c.nom, d.categorie, d.statut,
                d.montant_accepte as prix,
                coalesce((select sum(case when p.type_mouvement='paiement'
                                          then p.montant else -p.montant end)
                          from local_paiements_commandes p
                          where p.dossier_id = d.id), 0) as encaisse,
                case when d.montant_accepte is null or d.statut = 'annulee'
                       then null
                     else d.montant_accepte - coalesce((select sum(case when p.type_mouvement='paiement'
                                                                       then p.montant else -p.montant end)
                                                        from local_paiements_commandes p
                                                        where p.dossier_id = d.id), 0)
                end as reste
         from local_dossiers_commandes d
         left join local_clients c on c.id = d.client_id
         where d.shop_id = '$SHOP'
         order by d.created_at;\"" 2>/dev/null | sed 's/^/  /'

    echo
    echo "— VERSEMENTS —"
    "$ADB" shell "run-as $PKG sqlite3 -header -column $DB \
      \"select substr(dossier_id,1,8) as dossier, type_mouvement, montant,
                mode_paiement, datetime(effectue_at,'unixepoch','localtime') as quand
         from local_paiements_commandes
         where shop_id = '$SHOP' order by effectue_at;\"" 2>/dev/null | sed 's/^/  /'

    echo
    echo "— CE QUI EST ARRIVÉ DANS LE TIROIR —"
    # Un acompte en espèces DOIT avoir sa ligne ici. S'il manque, la clôture
    # annoncera un surplus du même montant (piège #32).
    "$ADB" shell "run-as $PKG sqlite3 -header -column $DB \
      \"select type, category, amount,
                datetime(created_at,'unixepoch','localtime') as quand
         from local_cash_movements
         where shop_id = '$SHOP'
           and category in ('Acompte commande','Remboursement commande')
         order by created_at;\"" 2>/dev/null | sed 's/^/  /'

    echo
    echo "— CONTRÔLE : espèces des commandes vs lignes de caisse —"
    "$ADB" shell "run-as $PKG sqlite3 $DB \
      \"select 'commandes en especes : ' || coalesce(sum(case when type_mouvement='paiement'
                                                              then montant else -montant end), 0)
         from local_paiements_commandes
         where shop_id = '$SHOP' and mode_paiement='especes';\"" 2>/dev/null | sed 's/^/  /'
    "$ADB" shell "run-as $PKG sqlite3 $DB \
      \"select 'lignes de caisse     : ' || coalesce(sum(case when type='incoming'
                                                              then amount else -amount end), 0)
         from local_cash_movements
         where shop_id = '$SHOP'
           and category in ('Acompte commande','Remboursement commande');\"" 2>/dev/null | sed 's/^/  /'
    echo "  (les deux nombres doivent être identiques)"
    ;;

  fin)
    exiger_appareil
    "$ADB" shell settings put global auto_time 1
    "$ADB" shell settings put global auto_time_zone 1
    "$ADB" shell settings put global airplane_mode_on 0
    "$ADB" shell svc wifi enable
    "$ADB" shell svc data enable
    sleep 5
    echo "heure et réseau rétablis : $("$ADB" shell date | tr -d '\r')"
    relancer
    echo
    echo "la file part toute seule. Pour la suivre :"
    echo "  $ADB logcat -d | grep 'flutter :' | grep SYNC | tail"
    ;;

  *)
    sed -n '2,23p' "$0" | sed 's/^# \?//'
    exit 1
    ;;
esac
