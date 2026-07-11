SHELL := /bin/bash
version := $(shell date +%Y.%-m.%-d)

.SILENT:
.PHONY: check validate details fetch-db update release \
        INE INF IN9 IN0 IN1 IN2 IN3 IN4 INA INB INC IND ING

check:
	for cmd in jq curl sed; do \
		command -v $$cmd >/dev/null 2>&1 || { echo >&2 "I require $$cmd but it's not installed."; exit 1; }; \
	done

# Fetch ISINs from NSDL search API across every issuer class.
# With 50k-row API pages every class fits in a few pages, so all classes
# fetch fully; --partial-okay only kicks in if the API shrinks page sizes.
SEARCH_CSV := search.csv

$(SEARCH_CSV): INE INF IN9 IN0 IN1 IN2 IN3 IN4 INA INB INC IND ING
	cat src/header.csv IN*.csv > $(SEARCH_CSV)
	rm IN*.csv

INE INF IN9 IN0 IN1 IN2 IN3 IN4 INA INB INC IND ING:
	./src/fetch.sh --partial-okay $@

# Download the latest ISIN_DETAILS CSV from NSDL. NSDL publishes the current
# file's path (carrying its own date) via a JSON listing API, so we read the
# exact path from there instead of guessing today's date. The resolved
# filename is written to $(DETAILS_STAMP) so a later `make release` uploads the
# same file. Missing/unreachable data is non-fatal: update/release skip it.
NSDL_DETAILS_API := https://nsdl.com/web/api//view/annual-reports/id-listing/securities_isin_code
DETAILS_STAMP := .details-file

details:
	rm -f $(DETAILS_STAMP); \
	path=$$(curl --fail -sS --connect-timeout 30 --retry 3 "$(NSDL_DETAILS_API)" \
		| jq -r '.[0].f // empty'); \
	if [ -z "$$path" ]; then \
		echo "Could not resolve ISIN_DETAILS path from NSDL API"; \
	else \
		file=$$(basename "$$path"); \
		if curl --fail -sS --connect-timeout 30 --retry 3 -o "$$file" "https://nsdl.com$$path"; then \
			echo "$$file" > $(DETAILS_STAMP); \
			echo "Downloaded $$file"; \
		else \
			rm -f "$$file"; echo "No Details CSV available ($$file)"; \
		fi; \
	fi

# Pull latest isin.db from previous GitHub release.
fetch-db:
	gh release download --pattern "isin.db" --clobber --dir . 2>/dev/null \
		|| echo "Starting fresh — no existing isin.db"

# Daily update flow:
#   1. fetch latest isin.db from previous release
#   2. fetch ISINs from NSDL search (partial for large classes)
#   3. download the latest ISIN_DETAILS CSV (path resolved via NSDL JSON API)
#   4. load both CSVs into isin.db (diffs go to isin_history)
update: fetch-db $(SEARCH_CSV) details
	uv run src/main.py load $(SEARCH_CSV)
	if [ -f $(DETAILS_STAMP) ]; then uv run src/main.py load "$$(cat $(DETAILS_STAMP))"; fi
	sed -i "s/^version.*/version: $(version)/" CITATION.cff
	sed -i "s/^date-released.*/date-released: $$(date --rfc-3339=date)/" CITATION.cff
	jq ".version = \"$(version)\" | .created = \"$$(date --rfc-3339=seconds)\"" datapackage.json > d2.json
	mv d2.json datapackage.json

# Sanity-check the release artifacts (DB integrity/row-count/sentinel ISINs and
# the Details CSV header/size) before publishing. Aborts release on any failure.
validate:
	uv run src/main.py check isin.db $$([ -f $(DETAILS_STAMP) ] && cat $(DETAILS_STAMP))

# Cut a new release with isin.db and today's Details CSV (idempotent on re-runs).
release: validate
	files="isin.db"; \
	[ -f $(DETAILS_STAMP) ] && files="$$files $$(cat $(DETAILS_STAMP))"; \
	if gh release view "v$(version)" >/dev/null 2>&1; then \
		gh release upload "v$(version)" --clobber $$files; \
	else \
		gh release create "v$(version)" --notes "" $$files; \
	fi
