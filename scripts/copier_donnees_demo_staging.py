#!/usr/bin/env python3
"""Copie trois boutiques de production vers les trois boutiques de test.

La source est toujours interrogée en SELECT. La destination est toujours le
projet staging explicite. Les identités/contacts clients et textes libres sont
remplacés ; produits, quantités, montants et dates métier sont conservés.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import tempfile
from decimal import Decimal
from pathlib import Path


PRODUCTION = "stbfrmodpjnqwzszrxty"
STAGING = "bjrmapcwfzrrvutozyfx"
COMPTE = "676028800@shoptrack.cm"
SOURCES = {
    "6b7c064f-0364-494c-bfdb-a181af0ee2a1": "e8a7adca-f56a-4e0b-83c8-f65b050eac01",
    "4a9f551d-052f-49b1-84f8-55bc26609e49": "e8a7adca-f56a-4e0b-83c8-f65b050eac02",
    "7efdcf2b-fe8c-42f8-8211-185295eda5ac": "e8a7adca-f56a-4e0b-83c8-f65b050eac03",
}
TABLES = (
    "products",
    "product_prices",
    "stock_movements",
    "stock_purchases",
    "stock_sync_operations",
    "inventory_counts",
    "inventory_losses",
    "shop_takings",
    "sales",
    "sale_items",
    "cash_movements",
    "daily_closings",
    "clients",
    "dossiers_commandes",
    "paiements_commandes",
    "stock_transfers",
)


def sql_valeur(value: object) -> str:
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float, Decimal)):
        return str(value)
    if isinstance(value, (dict, list)):
        return sql_valeur(json.dumps(value, ensure_ascii=False, default=str)) + "::jsonb"
    return "'" + str(value).replace("'", "''") + "'"


def requete(ref: str, sql: str, travail: Path) -> list[dict]:
    fichier = travail / "requete.sql"
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
        (travail / "erreur.log").write_text(resultat.stderr)
        raise RuntimeError(f"Échec CLI sur {ref}; voir le journal temporaire sécurisé")
    try:
        payload = json.loads(resultat.stdout, parse_float=Decimal)
    except json.JSONDecodeError as erreur:
        (travail / "erreur.log").write_text(resultat.stdout)
        raise RuntimeError(f"Réponse non JSON sur {ref}") from erreur
    if "error" in payload:
        (travail / "erreur.log").write_text(json.dumps(payload, default=str))
        raise RuntimeError(f"Erreur SQL sur {ref}; voir le journal temporaire sécurisé")
    return payload.get("rows", [])


def condition_shop() -> str:
    return "(" + ",".join(sql_valeur(x) for x in SOURCES) + ")"


def exporter(travail: Path) -> dict[str, list[dict]]:
    source_ids = condition_shop()
    resultat: dict[str, list[dict]] = {}
    for table in TABLES:
        if table == "sale_items":
            filtre = f"sale_id in (select id from public.sales where shop_id in {source_ids})"
        elif table == "stock_transfers":
            filtre = f"from_shop_id in {source_ids} or to_shop_id in {source_ids}"
        else:
            filtre = f"shop_id in {source_ids}"
        resultat[table] = requete(
            PRODUCTION, f"select * from public.{table} where {filtre};", travail
        )
        print(f"Source {table}: {len(resultat[table])} lignes", flush=True)

    transferts = resultat["stock_transfers"]
    autres_shops = sorted(
        {
            row[cote]
            for row in transferts
            for cote in ("from_shop_id", "to_shop_id")
            if row[cote] not in SOURCES
        }
    )
    resultat["shops_lies"] = [{"id": identifiant} for identifiant in autres_shops]
    produits_connus = {row["id"] for row in resultat["products"]}
    produits_externes = sorted(
        {row["product_id"] for row in transferts} - produits_connus
    )
    if produits_externes:
        ids = ",".join(sql_valeur(x) for x in produits_externes)
        resultat["products_externes"] = requete(
            PRODUCTION, f"select * from public.products where id in ({ids});", travail
        )
        if len(resultat["products_externes"]) != len(produits_externes):
            raise RuntimeError("Produit lié à un transfert introuvable")
    else:
        resultat["products_externes"] = []
    print(
        f"Transferts: {len(transferts)} lignes, "
        f"{len(autres_shops)} points liés masqués et "
        f"{len(resultat['products_externes'])} produits associés",
        flush=True,
    )
    return resultat


def transformer(table: str, row: dict, owner: str, index: int) -> dict:
    row = dict(row)
    if "shop_id" in row:
        row["shop_id"] = SOURCES.get(row["shop_id"], row["shop_id"])
    if "from_shop_id" in row:
        row["from_shop_id"] = SOURCES.get(row["from_shop_id"], row["from_shop_id"])
        row["to_shop_id"] = SOURCES.get(row["to_shop_id"], row["to_shop_id"])
        if "from_shop_name" in row:
            row["from_shop_name"] = "Point de vente TEST"
        if "to_shop_name" in row:
            row["to_shop_name"] = "Point de vente TEST"
    for champ in ("user_id", "created_by", "annule_par"):
        if champ in row and row[champ] is not None:
            row[champ] = owner
    for champ in ("note", "reference_externe", "photo_url"):
        if champ in row:
            row[champ] = None
    if table == "clients":
        row["nom"] = f"Client test {index + 1:03d}"
        for champ in ("telephone", "whatsapp", "adresse"):
            row[champ] = None
    if table == "dossiers_commandes":
        row["description"] = f"Commande test {index + 1:03d} ({row['categorie']})"
        row["details"] = {}
        if row.get("motif_annulation") is not None:
            row["motif_annulation"] = "Motif masqué pour le test"
    return row


def inserer(table: str, rows: list[dict], travail: Path) -> None:
    for depart in range(0, len(rows), 80):
        lot = rows[depart:depart + 80]
        colonnes = list(lot[0])
        valeurs = ",\n".join(
            "(" + ",".join(sql_valeur(row[col]) for col in colonnes) + ")"
            for row in lot
        )
        sql = (
            f"insert into public.{table} "
            f"({','.join(colonnes)}) values\n{valeurs}\n"
            "on conflict do nothing;"
        )
        try:
            requete(STAGING, sql, travail)
        except RuntimeError as erreur:
            raise RuntimeError(
                f"Import {table}, lignes {depart + 1}-{depart + len(lot)}: {erreur}"
            ) from erreur
    print(f"Staging {table}: {len(rows)} lignes proposées", flush=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execute", action="store_true", help="écrit sur staging")
    args = parser.parse_args()
    if not args.execute:
        parser.error("Passer --execute pour la copie staging")
    with tempfile.TemporaryDirectory(prefix="shoptrack-copie-", dir="/tmp") as chemin:
        os.chmod(chemin, 0o700)
        travail = Path(chemin)
        owner_rows = requete(
            STAGING,
            "select id from auth.users where email=" + sql_valeur(COMPTE) + ";",
            travail,
        )
        if len(owner_rows) != 1:
            raise RuntimeError("Le compte de test staging manque")
        owner = owner_rows[0]["id"]
        data = exporter(travail)
        # Les identifiants fixes du jeu de démonstration ne sont effacés que
        # dans les trois boutiques créées pour ce compte, jamais ailleurs.
        requete(STAGING, """
            begin;
            delete from public.dossiers_commandes where id::text like 'e8a7adca-f56a-4e0b-83c8-f65b050ea7%';
            delete from public.clients where id::text like 'e8a7adca-f56a-4e0b-83c8-f65b050ea8%';
            delete from public.inventory_counts where id::text like 'e8a7adca-f56a-4e0b-83c8-f65b050eaa%';
            delete from public.shop_takings where id::text like 'e8a7adca-f56a-4e0b-83c8-f65b050ea9%';
            delete from public.products where id::text like 'e8a7adca-f56a-4e0b-83c8-f65b050eab%';
            update public.shops set name='TEST Copie Gildas' where id='e8a7adca-f56a-4e0b-83c8-f65b050eac01' and owner_id=
              (select id from auth.users where email='676028800@shoptrack.cm');
            update public.shops set name='TEST Copie Cédric Telecom' where id='e8a7adca-f56a-4e0b-83c8-f65b050eac02' and owner_id=
              (select id from auth.users where email='676028800@shoptrack.cm');
            update public.shops set name='TEST Copie aislynnconcept' where id='e8a7adca-f56a-4e0b-83c8-f65b050eac03' and owner_id=
              (select id from auth.users where email='676028800@shoptrack.cm');
            commit;
        """, travail)
        for index, shop in enumerate(data["shops_lies"]):
            inserer("shops", [{
                "id": shop["id"], "owner_id": None,
                "name": f"Point de vente lié TEST {index + 1}",
            }], travail)
        inserer("products", [
            transformer("products", row, owner, i)
            for i, row in enumerate(data["products"] + data["products_externes"])
        ], travail)
        for table in TABLES[1:]:
            rows = [transformer(table, row, owner, i) for i, row in enumerate(data[table])]
            if rows:
                inserer(table, rows, travail)
        print("Copie staging terminée : production interrogée en SELECT uniquement.")


if __name__ == "__main__":
    main()
