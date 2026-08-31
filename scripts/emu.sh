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
#   ./scripts/emu.sh jour 23        passe au 23 août 2026 et relance l'app
#   ./scripts/emu.sh jour 2026-09-04   une date complète, si besoin
#   ./scripts/emu.sh etat           date, réseau, file d'attente
#   ./scripts/emu.sh fin            rétablit heure et réseau, puis synchronise
set -euo pipefail

ADB=/home/jack/Android/Sdk/platform-tools/adb
PKG=cm.shoptrack.shoptrack
DB=/data/data/$PKG/app_flutter/shoptrack_local.sqlite

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
    jour="$2"
    # Un simple numéro suffit pendant la simulation d'août 2026.
    [[ "$jour" =~ ^[0-9]{1,2}$ ]] && jour="2026-08-$(printf '%02d' "$jour")"
    "$ADB" shell "date -s '$jour 08:00:00'" >/dev/null 2>&1
    echo "date du téléphone : $("$ADB" shell date | tr -d '\r')"
    # Rappel utile : hors ligne c'est sans danger, en ligne ça casse.
    if [ "$("$ADB" shell settings get global airplane_mode_on | tr -d '\r')" != "1" ]; then
      echo "  ⚠️  le réseau est ACTIF : avec une date décalée, les requêtes"
      echo "      seront refusées. Lance d'abord : $0 hors-ligne"
    fi
    relancer
    ;;

  etat)
    echo "date      : $("$ADB" shell date | tr -d '\r')"
    echo "mode avion: $("$ADB" shell settings get global airplane_mode_on | tr -d '\r')"
    echo "boutique  : $("$ADB" shell run-as $PKG cat /data/data/$PKG/shared_prefs/FlutterSharedPreferences.xml 2>/dev/null | grep -oE 'cached_shop_name">[^<]*' | cut -d'>' -f2)"
    echo "en attente d'envoi :"
    "$ADB" shell "run-as $PKG sqlite3 $DB \"select count(*) from sync_queue_items;\"" 2>/dev/null \
      | sed 's/^/  /'
    ;;

  fin)
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
    sed -n '2,30p' "$0" | sed 's/^# \?//'
    exit 1
    ;;
esac
