# /// script
# requires-python = ">=3.14"
# dependencies = [
#     "click",
# ]
# ///
import csv
import io
import json
import re
import sqlite3
from datetime import date, datetime
from pathlib import Path

import click

HERE = Path(__file__).parent
SCHEMA = (HERE / "schema_sqlite.sql").read_text()

ISIN_CSV_MAP = {
    "Issuer": "issuer_name",
    "Description": "description",
    "Type": "security_type_name",
    "Status": "status",
}

DETAILS_CSV_MAP = {
    "NAME_OF_ISSUER": "issuer_name",
    "SECURITY_DESCRIPTION": "description",
    "CURRENCY": "currency",
    "INTEREST_RATE": "interest_rate",
    "MATURITY_DATE": "maturity_date",
    "FISN": "fisn",
    "CFI": "cfi",
}

ISIN_COLS = [
    "isin", "issuer_name", "description", "security_type_name", "status",
    "currency", "interest_rate", "maturity_date", "fisn", "cfi",
    "issuer_type", "issuer_code", "security_type_code", "last_updated", "source",
]


def parse_isin_parts(isin: str) -> dict:
    if len(isin) >= 9 and isin.startswith("IN"):
        return {
            "issuer_type": isin[2],
            "issuer_code": isin[3:7],
            "security_type_code": isin[7:9],
        }
    return {"issuer_type": None, "issuer_code": None, "security_type_code": None}


def get_conn(db_path: str) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA synchronous=NORMAL")
    conn.execute("PRAGMA foreign_keys=ON")
    conn.executescript(SCHEMA)
    return conn


def load_isin_table(conn: sqlite3.Connection) -> dict:
    """Load all ISINs from SQLite into a {isin: {field: value}} dict."""
    cur = conn.execute(f"SELECT {','.join(ISIN_COLS)} FROM isin")
    return {row[0]: dict(zip(ISIN_COLS, row)) for row in cur}


def upsert_batch(
    conn: sqlite3.Connection,
    rows: list[tuple[str, dict]],
    state: dict,
    source: str,
    ts: str,
) -> tuple[int, int]:
    """
    rows: [(isin, {db_col: value})]
    state: in-memory current state, modified in place.
    Returns (inserts, updates).
    """
    inserts = []   # (isin, fields) for new rows
    updates = []   # (isin, changes) for changed rows
    hist = []      # (isin, json, source, ts) for history

    for isin, fields in rows:
        old = state.get(isin)

        if old is None:
            parts = parse_isin_parts(isin)
            merged = {**parts, **fields}
            state[isin] = {**merged, "source": source, "last_updated": ts}
            inserts.append((isin, merged))
            hist.append((isin, json.dumps({"_op": "insert", **fields}), source, ts))

        else:
            changes = {
                f: {"old": str(old.get(f) or ""), "new": str(v)}
                for f, v in fields.items()
                if v is not None and str(v) and str(v) != str(old.get(f) or "")
            }
            if changes:
                for f, d in changes.items():
                    state[isin][f] = d["new"]
                state[isin]["source"] = source
                state[isin]["last_updated"] = ts
                updates.append((isin, changes))
                hist.append((isin, json.dumps(changes), source, ts))

    if inserts:
        ph = ",".join("?" * len(ISIN_COLS))
        rows_to_insert = []
        for isin, fields in inserts:
            row = {**state[isin], "isin": isin}
            rows_to_insert.append(tuple(row.get(c) for c in ISIN_COLS))
        conn.executemany(f"INSERT INTO isin ({','.join(ISIN_COLS)}) VALUES ({ph})", rows_to_insert)

    for isin, changes in updates:
        set_cols = list(changes.keys())
        conn.execute(
            f"UPDATE isin SET {', '.join(f'{c}=?' for c in set_cols)}, "
            f"source=?, last_updated=? WHERE isin=?",
            [changes[c]["new"] for c in set_cols] + [source, ts, isin],
        )

    if hist:
        conn.executemany(
            "INSERT INTO isin_history (isin, changed_fields, source, recorded_at) VALUES (?,?,?,?)",
            hist,
        )

    return len(inserts), len(updates)


def parse_csv_rows(csv_text: str, col_map: dict) -> list[tuple[str, dict]]:
    """Parse CSV text into [(isin, {db_col: value})] using col_map."""
    rows = []
    reader = csv.DictReader(io.StringIO(csv_text))
    for row in reader:
        isin = row.get("ISIN", "").strip().strip('"')
        if not isin or not isin.startswith("IN"):
            continue
        fields = {}
        for csv_col, db_col in col_map.items():
            val = row.get(csv_col, "").strip().strip('"')
            if val and val.lower() != "null":
                fields[db_col] = val
        if "interest_rate" in fields:
            try:
                fields["interest_rate"] = float(fields["interest_rate"])
            except ValueError:
                del fields["interest_rate"]
        rows.append((isin, fields))
    return rows


def date_from_details_filename(filename: str) -> str:
    """'ISIN_DETAILS_16-Apr-2026.csv' → '2026-04-16'"""
    m = re.search(r"(\d{1,2})-(\w{3})-(\d{4})", filename)
    if m:
        try:
            return datetime.strptime(f"{m.group(1)}-{m.group(2)}-{m.group(3)}", "%d-%b-%Y").date().isoformat()
        except ValueError:
            pass
    return date.today().isoformat()


@click.group()
def cli():
    """India ISIN Data — SQLite tool."""


@cli.command()
@click.argument("csv_path", type=click.Path(exists=True))
@click.option("--db", "db_path", default="isin.db")
def load(csv_path, db_path):
    """Load ISIN.csv or ISIN_DETAILS CSV into SQLite."""
    conn = get_conn(db_path)
    state = load_isin_table(conn)

    csv_path = Path(csv_path)
    text = csv_path.read_text(encoding="utf-8", errors="replace")
    first_line = text.split("\n", 1)[0]

    if "NAME_OF_ISSUER" in first_line:
        col_map = DETAILS_CSV_MAP
        ts = date_from_details_filename(csv_path.name)
        source = f"details:{csv_path.name}"
    else:
        col_map = ISIN_CSV_MAP
        ts = date.today().isoformat()
        source = f"isin_csv:{ts}"

    rows = parse_csv_rows(text, col_map)

    with conn:
        inserts, updates = upsert_batch(conn, rows, state, source, ts)

    click.echo(f"Loaded {csv_path.name}: +{inserts} new, ~{updates} changed")
    conn.close()


@cli.command()
@click.argument("db_path", default="isin.db")
def stats(db_path):
    """Print database statistics."""
    conn = get_conn(db_path)

    isin_count = conn.execute("SELECT COUNT(*) FROM isin").fetchone()[0]
    hist_count = conn.execute("SELECT COUNT(*) FROM isin_history").fetchone()[0]
    loaded_count = conn.execute("SELECT COUNT(*) FROM loaded_files").fetchone()[0]

    click.echo(f"ISINs:            {isin_count:>10,}")
    click.echo(f"History entries:  {hist_count:>10,}")
    click.echo(f"Loaded CSV files: {loaded_count:>10,}")

    click.echo("\nBy source:")
    for source, count in conn.execute(
        "SELECT source, COUNT(*) FROM isin GROUP BY source ORDER BY COUNT(*) DESC LIMIT 20"
    ):
        click.echo(f"  {(source or '(none)'):<45} {count:>8,}")

    if hist_count > 0:
        click.echo("\nRecent history:")
        for row in conn.execute(
            "SELECT isin, source, recorded_at, changed_fields "
            "FROM isin_history ORDER BY recorded_at DESC LIMIT 10"
        ):
            isin, src, ts, cf = row
            click.echo(f"  {ts[:10]}  {isin}  ({src})")

    conn.close()


@cli.command()
@click.argument("isin_code")
@click.option("--db", "db_path", default="isin.db")
def history(isin_code, db_path):
    """Show change history for a specific ISIN."""
    conn = get_conn(db_path)

    row = conn.execute("SELECT * FROM isin WHERE isin = ?", (isin_code,)).fetchone()
    if not row:
        click.echo(f"ISIN {isin_code} not found.")
        return

    cols = [d[0] for d in conn.execute("SELECT * FROM isin LIMIT 0").description]
    click.echo(f"Current state of {isin_code}:")
    for col, val in zip(cols, row):
        if val is not None:
            click.echo(f"  {col:<22} {val}")

    hist = conn.execute(
        "SELECT changed_fields, source, recorded_at FROM isin_history "
        "WHERE isin = ? ORDER BY recorded_at",
        (isin_code,),
    ).fetchall()

    if not hist:
        click.echo("\nNo change history.")
        return

    click.echo(f"\nHistory ({len(hist)} entries):")
    for cf_json, src, ts in hist:
        cf = json.loads(cf_json)
        if cf.get("_op") == "insert":
            fields = {k: v for k, v in cf.items() if k != "_op"}
            click.echo(f"\n  {ts[:10]} ({src}): INSERT {json.dumps(fields)}")
        else:
            click.echo(f"\n  {ts[:10]} ({src}):")
            for field, diff in cf.items():
                click.echo(f"    {field}: {diff['old']!r} → {diff['new']!r}")

    conn.close()


if __name__ == "__main__":
    cli()
