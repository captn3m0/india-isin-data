# /// script
# requires-python = ">=3.14"
# dependencies = [
#     "click",
# ]
# ///
import csv
import io
import json
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
    "last_updated", "source",
]

UPSERT_SQL = (
    f"INSERT INTO isin ({','.join(ISIN_COLS)}) "
    f"VALUES ({','.join('?' * len(ISIN_COLS))}) "
    f"ON CONFLICT(isin) DO UPDATE SET "
    + ", ".join(f"{c}=excluded.{c}" for c in ISIN_COLS if c != "isin")
)


def get_conn(db_path: str) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA synchronous=NORMAL")
    conn.execute("PRAGMA foreign_keys=ON")
    conn.executescript(SCHEMA)
    return conn


def load_isin_table(conn: sqlite3.Connection) -> dict:
    cur = conn.execute(f"SELECT {','.join(ISIN_COLS)} FROM isin")
    return {row[0]: dict(zip(ISIN_COLS, row)) for row in cur}


def diff(old: dict, fields: dict) -> dict:
    """Compare new fields against current state. Returns {col: {old?, new}}."""
    changes = {}
    for f, v in fields.items():
        if v is None:
            continue
        new_str = str(v)
        if not new_str:
            continue
        old_str = str(old.get(f) or "")
        if new_str == old_str:
            continue
        changes[f] = {"old": old_str, "new": new_str} if old_str else {"new": new_str}
    return changes


def upsert_batch(conn, rows, state, source, ts):
    """Apply CSV rows to state and SQLite. Returns (inserts, updates)."""
    inserts = updates = 0
    rows_to_write = []
    history = []

    for isin, fields in rows:
        old = state.get(isin)
        if old is None:
            state[isin] = {"isin": isin, **fields, "source": source, "last_updated": ts}
            rows_to_write.append(state[isin])
            inserts += 1
        else:
            changes = diff(old, fields)
            if not changes:
                continue
            for f, d in changes.items():
                state[isin][f] = d["new"]
            state[isin]["source"] = source
            state[isin]["last_updated"] = ts
            rows_to_write.append(state[isin])
            history.append((isin, json.dumps(changes), source, ts))
            updates += 1

    if rows_to_write:
        conn.executemany(
            UPSERT_SQL,
            [tuple(r.get(c) for c in ISIN_COLS) for r in rows_to_write],
        )
    if history:
        conn.executemany(
            "INSERT INTO isin_history (isin, changed_fields, source, recorded_at) "
            "VALUES (?,?,?,?)",
            history,
        )
    return inserts, updates


def parse_csv(text: str, col_map: dict) -> list[tuple[str, dict]]:
    """Parse CSV text into [(isin, {db_col: value})]. Drops blanks and 'null'."""
    out = []
    for row in csv.DictReader(io.StringIO(text)):
        isin = (row.get("ISIN") or "").strip()
        if not isin.startswith("IN"):
            continue
        fields = {}
        for csv_col, db_col in col_map.items():
            val = (row.get(csv_col) or "").strip()
            if val and val.lower() != "null":
                fields[db_col] = val
        if "interest_rate" in fields:
            try:
                fields["interest_rate"] = float(fields["interest_rate"])
            except ValueError:
                del fields["interest_rate"]
        out.append((isin, fields))
    return out


def date_from_details_filename(filename: str) -> str:
    """'ISIN_DETAILS_16-Apr-2026.csv' → '2026-04-16'"""
    try:
        date_part = filename.removeprefix("ISIN_DETAILS_").removesuffix(".csv")
        return datetime.strptime(date_part, "%d-%b-%Y").date().isoformat()
    except ValueError:
        return date.today().isoformat()


@click.group()
def cli():
    """India ISIN Data — SQLite tool."""


@cli.command()
@click.argument("csv_path", type=click.Path(exists=True))
@click.option("--db", "db_path", default="isin.db")
def load(csv_path, db_path):
    """Load a CSV (Search format or ISIN_DETAILS) into isin.db."""
    csv_path = Path(csv_path)
    text = csv_path.read_text(encoding="utf-8", errors="replace")

    if "NAME_OF_ISSUER" in text.split("\n", 1)[0]:
        col_map = DETAILS_CSV_MAP
        ts = date_from_details_filename(csv_path.name)
        source = f"details:{ts}"
    else:
        col_map = ISIN_CSV_MAP
        ts = date.today().isoformat()
        source = f"search:{ts}"

    rows = parse_csv(text, col_map)
    conn = get_conn(db_path)
    state = load_isin_table(conn)
    with conn:
        inserts, updates = upsert_batch(conn, rows, state, source, ts)
    conn.close()
    click.echo(f"Loaded {csv_path.name}: +{inserts} new, ~{updates} changed")


@cli.command()
@click.argument("db_path", default="isin.db")
def stats(db_path):
    """Print database statistics."""
    conn = get_conn(db_path)
    isin_count = conn.execute("SELECT COUNT(*) FROM isin").fetchone()[0]
    hist_count = conn.execute("SELECT COUNT(*) FROM isin_history").fetchone()[0]
    with_history = conn.execute("SELECT COUNT(DISTINCT isin) FROM isin_history").fetchone()[0]

    click.echo(f"ISINs:              {isin_count:>10,}")
    click.echo(f"ISINs with history: {with_history:>10,}")
    click.echo(f"History entries:    {hist_count:>10,}")

    click.echo("\nBy source:")
    for source, count in conn.execute(
        "SELECT source, COUNT(*) FROM isin GROUP BY source ORDER BY COUNT(*) DESC LIMIT 20"
    ):
        click.echo(f"  {(source or '(none)'):<45} {count:>8,}")

    if hist_count:
        click.echo("\nRecent history:")
        for isin, src, ts, _ in conn.execute(
            "SELECT isin, source, recorded_at, changed_fields "
            "FROM isin_history ORDER BY recorded_at DESC LIMIT 10"
        ):
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
        click.echo(f"\n  {ts[:10]} ({src}):")
        for field, d in json.loads(cf_json).items():
            if "old" in d:
                click.echo(f"    {field}: {d['old']!r} → {d['new']!r}")
            else:
                click.echo(f"    {field}: + {d['new']!r}")

    conn.close()


if __name__ == "__main__":
    cli()
