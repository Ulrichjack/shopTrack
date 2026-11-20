#!/usr/bin/env bash
# Construire les APK à livrer, avec le bon numéro de version dedans.
#
# POURQUOI CE SCRIPT : l'écran de profil affichait « ShopTrack vdev » sur un
# APK destiné à une cliente. La version se lit par `--dart-define`, et il suffit
# de l'oublier une fois pour livrer un binaire qui ne sait pas ce qu'il est.
# C'est la première chose qu'on demande au téléphone quand quelque chose ne va
# pas — une fausse réponse envoie chercher dans le mauvais code.
#
# ⚠️ TOUJOURS `--split-per-abi`, jamais un APK universel.
#
# Flutter décale le `versionCode` selon l'architecture : arm64 vaut 2000 + n,
# l'universel vaut n. Livrer un universel par-dessus un split, c'est proposer
# un « retour en arrière » qu'Android refuse — sans jamais dire pourquoi.
# Constaté le 02/09, une heure perdue à chercher du côté de la signature.
set -euo pipefail

cd "$(dirname "$0")/.."
VERSION=$(grep '^version:' pubspec.yaml | cut -d' ' -f2)
NOM=$(echo "$VERSION" | cut -d'+' -f1)

echo "→ ShopTrack $VERSION"
flutter build apk --release --flavor production --split-per-abi \
  --dart-define=VERSION_APP="$NOM"

BUREAU="$HOME/Bureau"
mkdir -p "$BUREAU"
rm -f "$BUREAU"/ShopTrack-*.apk

APKSIGNER=$(find "$HOME/Android/Sdk/build-tools" -name apksigner 2>/dev/null | sort -V | tail -1)
AAPT=$(find "$HOME/Android/Sdk/build-tools" -name aapt2 2>/dev/null | sort -V | tail -1)

for abi in arm64-v8a armeabi-v7a; do
  src="build/app/outputs/flutter-apk/app-$abi-production-release.apk"
  if [ ! -f "$src" ]; then
    echo "  ❌ APK production introuvable : $src"
    exit 1
  fi
  court=$([ "$abi" = "arm64-v8a" ] && echo arm64 || echo armv7)
  dest="$BUREAU/ShopTrack-$NOM-$court.apk"
  cp "$src" "$dest"
  package=$("$AAPT" dump badging "$dest" 2>/dev/null | sed -n "s/^package: name='\([^']*\)'.*/\1/p")
  if [ "$package" != "cm.shoptrack.shoptrack" ]; then
    echo "  ❌ Identifiant Android inattendu : $package"
    exit 1
  fi
  code=$("$AAPT" dump badging "$dest" 2>/dev/null | grep -oE "versionCode='[0-9]+'" | cut -d"'" -f2)
  sig=$("$APKSIGNER" verify --print-certs "$dest" 2>&1 | grep -oE "SHA-256 digest: [a-f0-9]+" | head -1 | cut -d' ' -f3)
  printf "  %-30s %9s octets  code=%s\n" "$(basename "$dest")" "$(stat -c%s "$dest")" "$code"
  # La signature ne doit JAMAIS changer : elle seule permet la mise à jour
  # par-dessus une installation existante, sans perdre les données.
  if [ "$sig" != "9108cdad63123ed1508cef9d4daf882fd9b995d4a082ad5f9ff9b8924b25ab86" ]; then
    echo "  ❌ SIGNATURE DIFFÉRENTE — ne pas livrer : $sig"
    exit 1
  fi
done
echo "  ✓ signature d'origine vérifiée sur les deux"
echo
echo "Livre l'arm64. L'armv7 ne sert qu'aux téléphones 32 bits."
