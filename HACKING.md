# Hacking

Every weekday at 18:00 IST, `.github/workflows/update.yml` runs `make update` followed by `make release`. Three things happen on every run.

First, `fetch-db` pulls the most recent `isin.db` from the latest GitHub release. This is the cumulative store containing every ISIN ever seen along with the full change history in `isin_history`. Without it the run would start empty.

Second, two data sources get loaded into `isin.db`. `src/fetch.sh --partial-okay` scrapes NSDL's master search across every issuer class. Small classes (IN0-IN4, INA-IND, ING) pull every page; large classes (INE at ~28k pages, INF at ~8k, IN9) fetch a date-indexed slice — pages where `page_no % 100 == day_of_year % 100` — so the full corpus rotates through in 100 days and every page gets revisited a few times a year. Today's `ISIN_DETAILS_DD-MMM-YYYY.csv` is downloaded from `nsdl.co.in/downloadables/excel/cp-debt/`. Both files go through `src/main.py load`, which diffs each row against current state and records every real change in `isin_history`.

Third, `make release` tags `v<date>` and attaches `isin.db` plus today's Details CSV as release artifacts. The chain of releases is the data history.
