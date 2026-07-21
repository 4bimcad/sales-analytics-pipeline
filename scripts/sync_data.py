"""
sync_data.py

Loads new purchase records into the `compras` table in Supabase (PostgreSQL).

How it works:
- Looks for CSV files in data/incoming/ (e.g. compras_2026-07-20.csv)
- Each CSV must have columns: cliente_id, curso_id, categoria_id,
  certificado_id, fecha_compra, monto
- Inserts rows using ON CONFLICT (id) DO NOTHING, so re-running the script
  or re-processing the same file never creates duplicates
- Moves processed files to data/incoming/processed/ so they aren't re-read
- Exits with a non-zero status code on any failure, so GitHub Actions marks
  the workflow run as failed and sends the built-in failure notification
  email automatically (no extra notification service needed)

Environment variables required (set as GitHub Actions secrets):
- DB_HOST
- DB_PORT   (default 5432)
- DB_NAME   (default postgres)
- DB_USER
- DB_PASSWORD
"""

import os
import sys
import glob
import shutil
import logging

import pandas as pd
import psycopg2
from psycopg2.extras import execute_values

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

INCOMING_DIR = os.path.join(os.path.dirname(__file__), "..", "data", "incoming")
PROCESSED_DIR = os.path.join(INCOMING_DIR, "processed")

REQUIRED_COLUMNS = [
    "cliente_id",
    "curso_id",
    "categoria_id",
    "certificado_id",
    "fecha_compra",
    "monto",
]


def get_connection():
    host = os.environ["DB_HOST"]
    port = os.environ.get("DB_PORT", "5432")
    dbname = os.environ.get("DB_NAME", "postgres")
    user = os.environ["DB_USER"]
    password = os.environ["DB_PASSWORD"]

    return psycopg2.connect(
        host=host, port=port, dbname=dbname, user=user, password=password
    )


def load_csv_files():
    os.makedirs(INCOMING_DIR, exist_ok=True)
    os.makedirs(PROCESSED_DIR, exist_ok=True)
    return sorted(glob.glob(os.path.join(INCOMING_DIR, "*.csv")))


def validate_dataframe(df, filepath):
    missing = [c for c in REQUIRED_COLUMNS if c not in df.columns]
    if missing:
        raise ValueError(
            f"{filepath} is missing required columns: {missing}"
        )
    if df[REQUIRED_COLUMNS].isnull().any().any():
        raise ValueError(f"{filepath} contains null values in required columns")


def insert_rows(conn, df):
    rows = [
        (
            int(r.cliente_id),
            int(r.curso_id),
            int(r.categoria_id),
            int(r.certificado_id) if not pd.isna(r.certificado_id) else None,
            str(r.fecha_compra),
            float(r.monto),
        )
        for r in df.itertuples(index=False)
    ]

    query = """
    INSERT INTO compras
        (cliente_id, curso_id, categoria_id, certificado_id, fecha_compra, monto)
    VALUES %s
    ON CONFLICT (cliente_id, curso_id, fecha_compra, monto) DO NOTHING
"""

    with conn.cursor() as cur:
        execute_values(cur, query, rows)
    conn.commit()
    return len(rows)


def main():
    files = load_csv_files()

    if not files:
        log.info("No new files found in data/incoming/. Nothing to do.")
        return

    conn = get_connection()
    total_inserted = 0

    try:
        for filepath in files:
            log.info(f"Processing {filepath}")
            df = pd.read_csv(filepath)
            validate_dataframe(df, filepath)

            inserted = insert_rows(conn, df)
            total_inserted += inserted
            log.info(f"Inserted/attempted {inserted} rows from {filepath}")

            # Move file to processed/ so it isn't picked up again
            dest = os.path.join(PROCESSED_DIR, os.path.basename(filepath))
            shutil.move(filepath, dest)

        log.info(f"Done. Total rows processed: {total_inserted}")

    except Exception:
        log.exception("Sync failed")
        conn.rollback()
        raise  # non-zero exit -> GitHub Actions marks the run as failed
    finally:
        conn.close()


if __name__ == "__main__":
    main()
