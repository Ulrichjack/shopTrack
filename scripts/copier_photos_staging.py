#!/usr/bin/env python3
"""Copie les photos produit publiques de production vers staging.

La production est lue seulement. Les URL de staging sont écrites uniquement sur
les trois boutiques de test de 676028800, jamais dans les boutiques clientes.
Les images sont transférées en mémoire, sans fichier local ni clé dans le dépôt.
"""

from __future__ import annotations

import argparse
import json
import mimetypes
import subprocess
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path


PRODUCTION = "stbfrmodpjnqwzszrxty"
STAGING = "bjrmapcwfzrrvutozyfx"
SOURCES = (
    "4a9f551d-052f-49b1-84f8-55bc26609e49",  # Cédric Telecom
    "7efdcf2b-fe8c-42f8-8211-185295eda5ac",  # aislynnconcept
)
CIBLES = (
    "e8a7adca-f56a-4e0b-83c8-f65b050eac02",
    "e8a7adca-f56a-4e0b-83c8-f65b050eac03",
)
PREFIXE_SOURCE = "/storage/v1/object/public/product-photos/"
MAX_IMAGE = 6 * 1024 * 1024


def query(ref: str, sql: str) -> list[dict]:
    with tempfile.TemporaryDirectory(prefix="shoptrack-photos-", dir="/tmp") as dossier:
        fichier = Path(dossier) / "requete.sql"
        fichier.write_text(sql)
        resultat = subprocess.run(
            [
                "supabase", "db", "query", "--linked", "--project-ref", ref,
                "--file", str(fichier), "--output-format", "json",
            ],
            capture_output=True,
            text=True,
            check=False,
        )
    if resultat.returncode != 0:
        raise RuntimeError(f"Échec de la requête Supabase {ref}")
    payload = json.loads(resultat.stdout)
    if "error" in payload:
        raise RuntimeError(f"Erreur SQL sur {ref}: {payload['error'].get('code', '?')}")
    return payload.get("rows", [])


def service_key() -> str:
    resultat = subprocess.run(
        ["supabase", "projects", "api-keys", "--project-ref", STAGING,
         "--output", "json"],
        capture_output=True,
        text=True,
        check=True,
    )
    for entree in json.loads(resultat.stdout):
        if entree.get("name") == "service_role":
            return entree["api_key"]
    raise RuntimeError("Clé service_role staging introuvable")


def copier_image(ligne: dict, cle: str) -> tuple[str, str]:
    source = ligne["photo_url"]
    url = urllib.parse.urlparse(source)
    if url.scheme != "https" or url.netloc != f"{PRODUCTION}.supabase.co":
        raise ValueError("Photo hors du stockage Supabase production attendu")
    if not url.path.startswith(PREFIXE_SOURCE):
        raise ValueError("Photo hors du bucket product-photos attendu")
    with urllib.request.urlopen(source, timeout=25) as reponse:
        content_type = reponse.headers.get_content_type()
        if content_type not in {"image/jpeg", "image/png", "image/webp"}:
            raise ValueError("Format d'image non pris en charge")
        contenu = reponse.read(MAX_IMAGE + 1)
    if len(contenu) > MAX_IMAGE:
        raise ValueError("Image trop grande pour le test")
    extension = mimetypes.guess_extension(content_type) or ".jpg"
    if extension == ".jpe":
        extension = ".jpg"
    objet = f"copies-test/{ligne['id']}{extension}"
    adresse = f"https://{STAGING}.supabase.co/storage/v1/object/product-photos/{objet}"
    requete = urllib.request.Request(
        adresse,
        data=contenu,
        headers={
            "Authorization": f"Bearer {cle}",
            "apikey": cle,
            "Content-Type": content_type,
            "x-upsert": "true",
        },
        method="POST",
    )
    for tentative in range(3):
        try:
            with urllib.request.urlopen(requete, timeout=35) as reponse:
                if reponse.status not in {200, 201}:
                    raise RuntimeError("Échec d'envoi dans le stockage staging")
            break
        except urllib.error.HTTPError as erreur:
            if tentative == 2 or erreur.code not in {429, 500, 502, 503, 504}:
                raise
            time.sleep(2 ** tentative)
    url_publique = (
        f"https://{STAGING}.supabase.co/storage/v1/object/public/"
        f"product-photos/{objet}"
    )
    return ligne["id"], url_publique


def sql_texte(valeur: str) -> str:
    return "'" + valeur.replace("'", "''") + "'"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execute", action="store_true", help="copie sur staging")
    args = parser.parse_args()
    if not args.execute:
        parser.error("Passer --execute pour la copie staging")
    liste = ",".join(sql_texte(x) for x in SOURCES)
    photos = query(
        PRODUCTION,
        f"select id,photo_url from public.products where shop_id in ({liste}) "
        "and photo_url is not null and btrim(photo_url) <> '';",
    )
    cibles = ",".join(sql_texte(x) for x in CIBLES)
    sans_photo = query(
        STAGING,
        f"select id from public.products where shop_id in ({cibles}) "
        "and photo_url is null;",
    )
    identifiants = {ligne["id"] for ligne in sans_photo}
    photos = [ligne for ligne in photos if ligne["id"] in identifiants]
    print(f"Photos restant à copier : {len(photos)}", flush=True)
    cle = service_key()
    copies: list[tuple[str, str]] = []
    echecs: list[str] = []
    with ThreadPoolExecutor(max_workers=2) as pool:
        futures = {pool.submit(copier_image, ligne, cle): ligne["id"] for ligne in photos}
        for futur in as_completed(futures):
            try:
                copies.append(futur.result())
            except (ValueError, RuntimeError, urllib.error.URLError) as erreur:
                code = f" {erreur.code}" if isinstance(erreur, urllib.error.HTTPError) else ""
                echecs.append(f"{futures[futur]}: {type(erreur).__name__}{code}")
    del cle
    for depart in range(0, len(copies), 50):
        lot = copies[depart:depart + 50]
        valeurs = ",".join(
            f"({sql_texte(identifiant)}::uuid,{sql_texte(url)})"
            for identifiant, url in lot
        )
        query(
            STAGING,
            "update public.products p set photo_url=v.url "
            f"from (values {valeurs}) as v(id,url) "
            f"where p.id=v.id and p.shop_id in ({cibles});",
        )
    print(f"Photos copiées et reliées sur staging : {len(copies)}", flush=True)
    if echecs:
        print(f"Photos non copiées : {len(echecs)}. IDs : "
              + ", ".join(echecs[:12]), flush=True)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
