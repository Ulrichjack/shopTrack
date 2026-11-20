#!/usr/bin/env python3
"""Produit les pages HTML depuis les mêmes textes que l'application Flutter.

Sans --apercu, un contenu marqué brouillon est refusé. --verifier contrôle
les fichiers déjà générés sans les modifier. Aucun déploiement réseau.
"""

import argparse
import html
import json
from pathlib import Path
from urllib.parse import quote


RACINE = Path(__file__).resolve().parents[1]
SOURCE = RACINE / "assets/legal/informations_fr.json"
SORTIE = RACINE / "website/legal"


def echapper(texte):
    return html.escape(texte, quote=True)


def rendre(contenu, document):
    navigation = "\n".join(
        f'<a href="{echapper(item["id"])}.html">{echapper(item["title"])}</a>'
        for item in contenu["documents"]
    )
    sections = "\n".join(
        "<section><h2>" + echapper(section["title"]) + "</h2>"
        + "".join("<p>" + echapper(p) + "</p>" for p in section["paragraphs"])
        + "</section>"
        for section in document["sections"]
    )
    avertissement = (
        '<aside role="note">' + echapper(contenu["draftNotice"]) + "</aside>"
        if contenu["draft"] else ""
    )
    robots = '<meta name="robots" content="noindex, nofollow">' if contenu["draft"] else ""
    contact = echapper(contenu["contact"])
    demande = ""
    if document["id"] == "suppression-compte":
        sujet = quote("ShopTrack — Suppression de mon compte", safe="")
        corps = quote(
            "Bonjour,\n\nJe souhaite faire supprimer mon compte ShopTrack et les "
            "données personnelles associées.\n\n"
            "Numéro utilisé pour me connecter : [à compléter]\n\n"
            "Merci de m’indiquer la vérification nécessaire et les suites données "
            "à ma demande. Je ne joins aucun mot de passe ni code PIN.", safe=""
        )
        demande = (
            f'<p><a class="action" href="mailto:{contact}?subject={sujet}&amp;body={corps}">'
            'Préparer une demande de suppression par e-mail</a></p>'
            '<p>Sans application de messagerie, écrivez directement à '
            f'<strong>{contact}</strong> avec l’objet « ShopTrack — Suppression de mon compte » '
            'et votre numéro de connexion. L’ouverture du lien ne transmet aucune demande.</p>'
        )
    return f'''<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
{robots}
<title>{echapper(document["title"])} — ShopTrack</title>
<style>
:root {{ color-scheme: light; font-family: system-ui, sans-serif; color: #17212b; background: #f8fafb; }}
body {{ max-width: 760px; margin: auto; padding: 24px 20px 48px; line-height: 1.65; overflow-wrap: anywhere; }}
nav {{ display: flex; flex-wrap: wrap; gap: 12px 24px; margin: 24px 0; }}
a {{ color: #125b52; text-underline-offset: 3px; }}
a:focus-visible {{ outline: 3px solid #125b52; outline-offset: 4px; }}
h1 {{ font-size: 2rem; line-height: 1.25; }}
h2 {{ font-size: 1.25rem; margin-top: 32px; }}
aside {{ padding: 16px; border: 1px solid #a56812; background: #fff7e6; border-radius: 8px; }}
.action {{ display: inline-block; padding: 12px 18px; background: #125b52; color: white; border-radius: 8px; }}
footer {{ margin-top: 36px; border-top: 1px solid #ccd5db; padding-top: 16px; font-size: .9rem; }}
</style>
</head>
<body>
<header><strong>ShopTrack</strong><nav aria-label="Informations juridiques">{navigation}</nav></header>
<main>
<h1>{echapper(document["title"])}</h1>
<p>Version {echapper(contenu["version"])}</p>
{avertissement}
{sections}
{demande}
</main>
<footer><p>{echapper(contenu["copyright"])}</p>
<p>Contact : <a href="mailto:{contact}">{contact}</a></p></footer>
</body>
</html>
'''


def main():
    arguments = argparse.ArgumentParser(description=__doc__)
    arguments.add_argument("--apercu", action="store_true")
    arguments.add_argument("--verifier", action="store_true")
    options = arguments.parse_args()
    contenu = json.loads(SOURCE.read_text(encoding="utf-8"))
    if contenu["draft"] and not options.apercu:
        arguments.error("Textes encore en brouillon : publication refusée. Utiliser --apercu pour une relecture locale.")

    if not options.verifier:
        SORTIE.mkdir(parents=True, exist_ok=True)
    for document in contenu["documents"]:
        destination = SORTIE / f'{document["id"]}.html'
        attendu = rendre(contenu, document)
        if options.verifier:
            if not destination.exists() or destination.read_text(encoding="utf-8") != attendu:
                raise SystemExit(f"Page absente ou périmée : {destination.relative_to(RACINE)}")
        else:
            destination.write_text(attendu, encoding="utf-8")
    print("3 pages vérifiées." if options.verifier else "3 pages générées localement ; aucune publication effectuée.")


if __name__ == "__main__":
    main()
