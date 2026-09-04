#!/usr/bin/env python3
"""Assembler un mode d'emploi : une capture à gauche, l'explication à droite.

POURQUOI CETTE MISE EN PAGE : une capture seule ne dit pas quoi faire, un texte
seul ne dit pas où. Côte à côte, on lit la phrase et on voit l'endroit sans
tourner la page.

Le fichier de contenu est un simple texte :

    == Titre de la page
    Un paragraphe.
    - une puce
    @ nom-de-la-capture
"""
import pathlib, sys
from PIL import Image, ImageDraw, ImageFont

L, H = 1654, 2339           # A4 à 200 ppp
MARGE = 90
VERT, GRIS, NOIR = (29, 158, 117), (110, 110, 110), (25, 25, 25)

def police(taille, gras=False):
    base = "/usr/share/fonts/truetype/dejavu/DejaVuSans"
    chemin = f"{base}-Bold.ttf" if gras else f"{base}.ttf"
    if not pathlib.Path(chemin).exists():
        return ImageFont.load_default()
    return ImageFont.truetype(chemin, taille)

F_TITRE, F_TEXTE, F_GRAS, F_PIED = (
    police(46, True), police(27), police(27, True), police(20))

def couper(d, texte, f, largeur):
    lignes, courante = [], ""
    for mot in texte.split():
        essai = f"{courante} {mot}".strip()
        if d.textlength(essai, font=f) <= largeur:
            courante = essai
        else:
            lignes.append(courante); courante = mot
    if courante:
        lignes.append(courante)
    return lignes

def rendre(pages, sortie, dossier, titre_doc, sous_titre):
    images = []
    for numero, page in enumerate(pages, start=1):
        img = Image.new("RGB", (L, H), "white")
        d = ImageDraw.Draw(img)
        d.rectangle([0, 0, L, 14], fill=VERT)

        y = MARGE
        d.text((MARGE, y), page["titre"], font=F_TITRE, fill=VERT)
        y += 90
        d.line([MARGE, y, L - MARGE, y], fill=(225, 225, 225), width=2)
        y += 40

        # La capture à gauche, sur 40 % de la largeur utile.
        colonne = None
        if page.get("image"):
            chemin = dossier / f"{page['image']}.png"
            if chemin.exists():
                capture = Image.open(chemin)
                largeur_max = int((L - 2 * MARGE) * 0.40)
                hauteur_max = H - y - MARGE - 60
                ratio = min(largeur_max / capture.width,
                            hauteur_max / capture.height)
                capture = capture.resize(
                    (int(capture.width * ratio), int(capture.height * ratio)))
                img.paste(capture, (MARGE, y))
                d.rectangle([MARGE - 2, y - 2,
                             MARGE + capture.width + 2, y + capture.height + 2],
                            outline=(215, 215, 215), width=2)
                colonne = MARGE + capture.width + 60

        x = colonne or MARGE
        largeur = L - MARGE - x
        for bloc in page["contenu"]:
            f = F_GRAS if bloc.startswith("**") else F_TEXTE
            texte = bloc.strip("*")
            if texte.startswith("- "):
                d.ellipse([x + 6, y + 13, x + 16, y + 23], fill=VERT)
                for i, ligne in enumerate(couper(d, texte[2:], f, largeur - 36)):
                    d.text((x + 36, y), ligne, font=f, fill=NOIR); y += 40
                y += 8
                continue
            if not texte:
                y += 22; continue
            for ligne in couper(d, texte, f, largeur):
                d.text((x, y), ligne, font=f, fill=NOIR); y += 40
            y += 14

        d.text((MARGE, H - 60), f"{titre_doc} — {sous_titre}",
               font=F_PIED, fill=GRIS)
        d.text((L - MARGE - 60, H - 60), str(numero), font=F_PIED, fill=GRIS)
        images.append(img)

    images[0].save(sortie, save_all=True, append_images=images[1:],
                   resolution=200.0)
    print(f"{sortie}  {len(images)} pages")

def lire(chemin):
    pages, courante = [], None
    for ligne in pathlib.Path(chemin).read_text().splitlines():
        if ligne.startswith("== "):
            if courante: pages.append(courante)
            courante = {"titre": ligne[3:], "contenu": [], "image": None}
        elif ligne.startswith("@ ") and courante:
            courante["image"] = ligne[2:].strip()
        elif courante is not None:
            courante["contenu"].append(ligne)
    if courante: pages.append(courante)
    return pages

if __name__ == "__main__":
    source, sortie, dossier, titre, sous = sys.argv[1:6]
    rendre(lire(source), sortie, pathlib.Path(dossier), titre, sous)
