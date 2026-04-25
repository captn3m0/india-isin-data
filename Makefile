SHELL := /bin/bash
version := $(shell date +%Y.%-m.%-d)

.SILENT:
.PHONY: check details fetch-db update release \
        INE INF IN9 IN0 IN1 IN2 IN3 IN4 INA INB INC IND ING

check:
	for cmd in pup jq parallel curl sed; do \
		command -v $$cmd >/dev/null 2>&1 || { echo >&2 "I require $$cmd but it's not installed."; exit 1; }; \
	done

# Fetch ISINs from NSDL master search across every issuer class.
# Large classes (INE, INF, IN9) are partial-fetched ~1/100 pages per day,
# rotating through the full corpus in 100 days. Small classes pull every page.
SEARCH_CSV := search.csv

$(SEARCH_CSV): INE INF IN9 IN0 IN1 IN2 IN3 IN4 INA INB INC IND ING
	cat src/header.csv IN*.csv > $(SEARCH_CSV)
	rm IN*.csv

INE INF IN9 IN0 IN1 IN2 IN3 IN4 INA INB INC IND ING:
	./src/fetch.sh --partial-okay $@

# Download today's ISIN_DETAILS CSV from NSDL.
DETAILS_DATE ?= $(shell date +%-d-%b-%Y)
DETAILS_FILE = ISIN_DETAILS_$(DETAILS_DATE).csv

details:
	curl --insecure --fail -sS -o $(DETAILS_FILE) \
		"https://nsdl.co.in/downloadables/excel/cp-debt/$(DETAILS_FILE)" \
		|| (rm -f $(DETAILS_FILE); echo "No Details CSV for $(DETAILS_DATE)")

# Pull latest isin.db from previous GitHub release.
fetch-db:
	gh release download --pattern "isin.db" --clobber --dir . 2>/dev/null \
		|| echo "Starting fresh — no existing isin.db"

# Daily update flow:
#   1. fetch latest isin.db from previous release
#   2. fetch ISINs from NSDL search (partial for large classes)
#   3. download today's ISIN_DETAILS CSV
#   4. load both CSVs into isin.db (diffs go to isin_history)
update: fetch-db $(SEARCH_CSV) details
	uv run src/sqlite_db.py load $(SEARCH_CSV)
	if [ -f $(DETAILS_FILE) ]; then uv run src/sqlite_db.py load $(DETAILS_FILE); fi
	sed -i "s/^version.*/version: $(version)/" CITATION.cff
	sed -i "s/^date-released.*/date-released: $$(date --rfc-3339=date)/" CITATION.cff
	jq ".version = \"$(version)\" | .created = \"$$(date --rfc-3339=seconds)\"" datapackage.json > d2.json
	mv d2.json datapackage.json

# Cut a new release with isin.db and today's Details CSV (idempotent on re-runs).
release:
	files="isin.db"; \
	[ -f $(DETAILS_FILE) ] && files="$$files $(DETAILS_FILE)"; \
	if gh release view "v$(version)" >/dev/null 2>&1; then \
		gh release upload "v$(version)" --clobber $$files; \
	else \
		gh release create "v$(version)" --notes "" $$files; \
	fi
