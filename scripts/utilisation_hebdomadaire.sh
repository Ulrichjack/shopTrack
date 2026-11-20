#!/usr/bin/env bash
# Rapport administratif en lecture seule sur la production ShopTrack.
# Usage : bash scripts/utilisation_hebdomadaire.sh
set -euo pipefail

cd "$(dirname "$0")/.."

for outil in supabase jq column; do
  if ! command -v "$outil" >/dev/null 2>&1; then
    echo "Outil manquant : $outil" >&2
    exit 1
  fi
done

ref_production="stbfrmodpjnqwzszrxty"
echo "Activité ShopTrack production — semaine courante, heure du Cameroun"
echo "Projet Supabase : $ref_production (lecture seule)"

resultat="$(supabase db query \
  --linked \
  --project-ref "$ref_production" \
  --file scripts/utilisation_hebdomadaire.sql \
  --output-format json)"

if [ "$(jq '.rows | length' <<< "$resultat")" -eq 0 ]; then
  echo "Aucun compte avec action, connexion ou inscription visible cette semaine."
  exit 0
fi

echo "Période : $(jq -r '.rows[0].debut_semaine' <<< "$resultat") inclus → $(jq -r '.rows[0].fin_exclue' <<< "$resultat") exclu"

jq -r '
  (["Compte", "Identifiant", "Boutique(s)", "Preuve", "Ventes", "Caisse",
    "Clotures", "Clients", "Commandes", "Paiements", "Transferts",
    "Boutiques creees", "Dernier geste (CM)", "Connexion (CM)", "Inscription (CM)"] | @tsv),
  (.rows[] | [.compte_id_court, .compte_masque, .boutiques, .preuve,
    .ventes, .caisse, .clotures, .clients, .commandes, .paiements,
    .transferts, .boutiques_creees, .dernier_geste_cm,
    .connexion_cm, .inscription_cm] | map(if . == null then "-" else tostring end) | @tsv)
' <<< "$resultat" | column -t -s $'\t'

echo "Une connexion ou une inscription ne prouve pas une utilisation métier."
echo "Une action hors ligne n'apparaît qu'après synchronisation."
