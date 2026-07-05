"""
PMAY-G / PMUY — Raw Data Loader (MySQL version)
=================================================
Purpose : Load the 4 raw government CSV files into MySQL as RAW staging
          tables. NO transformation happens here — that's done in SQL
          (see sql/01_dim_states.sql onwards).

Why split this way:
  - Python  -> dumb, reliable file ingestion (handles file I/O, connection, schema push)
  - MySQL SQL -> all real ETL logic (unpivoting, cleaning, joins, KPIs)

Tech: Python 3.10+, mysql-connector-python, pandas, sqlalchemy

Setup (run once):
    pip install mysql-connector-python pandas sqlalchemy --break-system-packages

Run:
    python load_raw_to_mysql.py --host localhost --user root --password YOUR_PASSWORD --database pmay_analytics
"""

import argparse
import logging
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine, text

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
)
logger = logging.getLogger(__name__)

# Map: local filename -> MySQL staging table name
FILES = {
    "fund_release_PMAYG_2019_2024.csv":           "raw_fund_release",
    "Total_house_sanctioned_PMAYG_2017_2020.csv": "raw_houses_sanctioned",
    "Physical_progress_PMAYG_2022.csv":           "raw_physical_progress",
    "No_of_PMUY_connection_2018_2023.csv":        "raw_pmuy_connections",
}

RAW_DATA_DIR = Path("D:/power bi/Gov Policy/data/raw")


def get_engine(host: str, user: str, password: str, database: str, port: int = 3306):
    """
    Create a SQLAlchemy engine for MySQL.
    Using SQLAlchemy (not raw mysql-connector) because pandas.to_sql()
    needs a SQLAlchemy-compatible engine to work cleanly.
    """
    connection_str = f"mysql+mysqlconnector://{user}:{password}@{host}:{port}/{database}"
    engine = create_engine(connection_str)
    return engine


def ensure_database_exists(host: str, user: str, password: str, database: str, port: int = 3306):
    """
    Create the database if it doesn't exist yet.
    Connects without specifying a database first, since the target DB
    might not exist.
    """
    root_connection_str = f"mysql+mysqlconnector://{user}:{password}@{host}:{port}/"
    root_engine = create_engine(root_connection_str)
    with root_engine.connect() as conn:
        conn.execute(text(f"CREATE DATABASE IF NOT EXISTS {database} CHARACTER SET utf8mb4"))
        conn.commit()
    logger.info("Database '%s' ready.", database)


def load_csv_to_mysql(engine, filepath: Path, table_name: str) -> None:
    """
    Load a single CSV as-is into a MySQL staging table.
    Uses if_exists='replace' so re-running the script is idempotent —
    each run drops and recreates the staging table fresh.
    All columns are loaded; cleaning happens later in SQL.
    """
    if not filepath.exists():
        logger.error("File not found: %s — skipping.", filepath)
        return

    # Light touch only: strip whitespace from headers so MySQL column
    # names are valid (no leading/trailing spaces). NO data cleaning,
    # NO renaming of state names, NO unpivoting here.
    df = pd.read_csv(filepath)
    df.columns = [c.strip() for c in df.columns]

    logger.info("Loading %s (%d rows, %d cols) -> table `%s`", filepath.name, len(df), len(df.columns), table_name)

    df.to_sql(
        name=table_name,
        con=engine,
        if_exists="replace",   # idempotent: drop + recreate each run
        index=False,
        chunksize=500,
    )

    logger.info("Loaded %d rows into `%s`.", len(df), table_name)


def main(host: str, user: str, password: str, database: str, port: int) -> None:
    ensure_database_exists(host, user, password, database, port)
    engine = get_engine(host, user, password, database, port)

    for filename, table_name in FILES.items():
        filepath = RAW_DATA_DIR / filename
        load_csv_to_mysql(engine, filepath, table_name)

    logger.info("=== All raw files loaded into MySQL. Run SQL ETL scripts next in MySQL Workbench. ===")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Load raw PMAY/PMUY CSVs into MySQL staging tables")
    parser.add_argument("--host",     default="localhost", help="MySQL host (default: localhost)")
    parser.add_argument("--user",     required=True,        help="MySQL username (e.g. root)")
    parser.add_argument("--password", required=True,        help="MySQL password")
    parser.add_argument("--database", default="pmay_analytics", help="Target database name")
    parser.add_argument("--port",     type=int, default=3306, help="MySQL port (default: 3306)")
    args = parser.parse_args()

    main(args.host, args.user, args.password, args.database, args.port)
