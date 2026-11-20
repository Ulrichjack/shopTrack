#!/usr/bin/env bash
# APK de test installable à côté de l'app cliente : aucune donnée réelle copiée.
set -euo pipefail

cd "$(dirname "$0")/.."

for outil in supabase jq; do
  if ! command -v "$outil" >/dev/null 2>&1; then
    echo "Outil manquant : $outil" >&2
    exit 1
  fi
done

sdk_flutter="$(sed -n 's/^flutter.sdk=//p' android/local.properties | head -n 1)/bin/flutter"
if [ ! -x "$sdk_flutter" ]; then
  echo "SDK Flutter introuvable dans android/local.properties" >&2
  exit 1
fi

ref_staging="bjrmapcwfzrrvutozyfx"
cle_publique="$(
  supabase projects api-keys --project-ref "$ref_staging" --output json \
    | jq -er '.[] | select(.name == "anon") | .api_key'
)"

if [ -z "$cle_publique" ]; then
  echo "Clé publique staging introuvable" >&2
  exit 1
fi

"$sdk_flutter" build apk --debug --flavor staging \
  --build-number=1010 \
  --dart-define=SHOPTRACK_BACKEND=staging \
  --dart-define=SHOPTRACK_STAGING_ANON_KEY="$cle_publique"
unset cle_publique

apk="build/app/outputs/flutter-apk/app-staging-debug.apk"
if [ ! -f "$apk" ]; then
  echo "APK staging introuvable : $apk" >&2
  exit 1
fi

android_sdk="$(sed -n 's/^sdk.dir=//p' android/local.properties | head -n 1)"
aapt="$(find "$android_sdk/build-tools" -maxdepth 2 -type f -name aapt | sort -V | tail -n 1)"
if [ -z "$aapt" ]; then
  echo "aapt introuvable : impossible de vérifier l'identifiant Android" >&2
  exit 1
fi
package="$("$aapt" dump badging "$apk" | sed -n "s/^package: name='\([^']*\)'.*/\1/p")"
if [ "$package" != 'cm.shoptrack.shoptrack.staging' ]; then
  echo "Identifiant Android staging inattendu : $package" >&2
  exit 1
fi

echo "APK de test : $apk"
echo "Identifiant vérifié : $package"
echo "Ne pas installer sur un téléphone client avant les tests complets."
