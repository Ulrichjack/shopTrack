#!/usr/bin/env bash
# Build statique de test, distinct du backend des clients.
set -euo pipefail
cd "$(dirname "$0")/.."

for outil in supabase jq; do
  command -v "$outil" >/dev/null 2>&1 || {
    echo "Outil manquant : $outil" >&2
    exit 1
  }
done

sdk_flutter="$(sed -n 's/^flutter.sdk=//p' android/local.properties | head -n 1)/bin/flutter"
if [ ! -x "$sdk_flutter" ]; then
  echo 'SDK Flutter introuvable' >&2
  exit 1
fi

ref_staging='bjrmapcwfzrrvutozyfx'
cle_publique="$(
  supabase projects api-keys --project-ref "$ref_staging" --output json \
    | jq -er '.[] | select(.name == "anon") | .api_key'
)"

"$sdk_flutter" build web --release --pwa-strategy=none -t lib/web/main_web.dart \
  --dart-define=SHOPTRACK_STAGING_ANON_KEY="$cle_publique"
unset cle_publique

mkdir -p build/web/legal
cp website/legal/*.html build/web/legal/

echo 'Web de test construit dans build/web (backend staging uniquement).'
