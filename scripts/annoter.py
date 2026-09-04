#!/usr/bin/env python3
"""Capturer un écran de l'émulateur et l'annoter pour le mode d'emploi.

POURQUOI CE SCRIPT : une capture brute ne montre pas OÙ appuyer. Une flèche
dessinée à la main dans un traitement de texte se décale au premier
redimensionnement. Ici l'annotation est posée sur les pixels, en coordonnées
relatives — elle suit l'image partout.

  ./scripts/annoter.py capturer 01-liste
  ./scripts/annoter.py annoter 01-liste "0.05,0.14,0.95,0.25:Ce qui reste à encaisser"
"""
import subprocess, sys, pathlib
from PIL import Image, ImageDraw, ImageFont

ADB = "/home/jack/Android/Sdk/platform-tools/adb"
DOSSIER = pathlib.Path("docs/guide-commandes")
ROUGE = (222, 45, 45)

def police(taille):
    for chemin in [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
    ]:
        if pathlib.Path(chemin).exists():
            return ImageFont.truetype(chemin, taille)
    return ImageFont.load_default()

def capturer(nom):
    DOSSIER.mkdir(parents=True, exist_ok=True)
    brut = subprocess.run(
        [ADB, "-s", "emulator-5554", "exec-out", "screencap", "-p"],
        capture_output=True, check=True).stdout
    chemin = DOSSIER / f"{nom}.png"
    chemin.write_bytes(brut)
    print(f"{chemin}  {Image.open(chemin).size}")

def annoter(nom, zones):
    """zones : « x1,y1,x2,y2:légende » en fractions de l'image (0 à 1)."""
    src = DOSSIER / f"{nom}.png"
    img = Image.open(src).convert("RGB")
    L, H = img.size
    d = ImageDraw.Draw(img)
    # Épaisseur proportionnelle : le même trait sur un écran deux fois plus
    # grand paraîtrait deux fois plus fin.
    trait = max(4, L // 180)
    f = police(max(26, L // 30))

    for numero, zone in enumerate(zones, start=1):
        coords, _, legende = zone.partition(":")
        x1, y1, x2, y2 = (float(v) for v in coords.split(","))
        boite = [x1 * L, y1 * H, x2 * L, y2 * H]
        d.rectangle(boite, outline=ROUGE, width=trait)

        # La pastille se pose DEHORS quand il y a la place, pour ne rien cacher
        # de ce qu'on montre — et DEDANS sinon. Placée dehors sans vérifier, la
        # première version la sortait de l'image : les repères 1 à 6 étaient
        # coupés par le bord droit.
        r = max(22, L // 36)
        marge = r * 2 + trait
        if boite[0] > marge:
            cx = boite[0] - r - trait
        elif boite[2] + marge < L:
            cx = boite[2] + r + trait
        else:
            cx = boite[2] - r - trait
        cy = boite[1] + r
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=ROUGE)
        t = str(numero)
        bb = d.textbbox((0, 0), t, font=f)
        d.text((cx - (bb[2] - bb[0]) / 2, cy - (bb[3] - bb[1]) / 2 - bb[1]),
               t, font=f, fill="white")

    sortie = DOSSIER / f"{nom}-annote.png"
    img.save(sortie)
    print(f"{sortie}  {len(zones)} repère(s)")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__); sys.exit(1)
    if sys.argv[1] == "capturer":
        capturer(sys.argv[2])
    else:
        annoter(sys.argv[2], sys.argv[3:])
