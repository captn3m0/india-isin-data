CREATE TABLE IF NOT EXISTS isin (
    isin                TEXT PRIMARY KEY,
    issuer_name         TEXT,
    description         TEXT,
    security_type_name  TEXT,
    status              TEXT,
    currency            TEXT,
    interest_rate       REAL,
    maturity_date       TEXT,
    fisn                TEXT,
    cfi                 TEXT,
    issuer_type         TEXT,
    issuer_code         TEXT,
    security_type_code  TEXT,
    last_updated        TEXT NOT NULL DEFAULT (datetime('now')),
    source              TEXT
);

CREATE TABLE IF NOT EXISTS isin_history (
    id              INTEGER PRIMARY KEY,
    isin            TEXT NOT NULL REFERENCES isin(isin),
    changed_fields  JSON NOT NULL,
    source          TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_isin_history_isin ON isin_history(isin);

CREATE TABLE IF NOT EXISTS loaded_files (
    filename    TEXT PRIMARY KEY,
    loaded_at   TEXT NOT NULL DEFAULT (datetime('now'))
);
