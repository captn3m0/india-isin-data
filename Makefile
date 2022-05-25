SHELL=/bin/bash
version=`date +%Y.%-m.%-d`

.SILENT:

check:
	for cmd in pup jq parallel curl sed;do \
		command -v $$cmd >/dev/null 2>&1 || { echo >&2 "I require $$cmd but it's not installed.  Aborting."; exit 1; }; \
	done

# Build Process
ISIN: INE INF IN9 IN0 IN1 IN2 IN3 IN4
	cat src/header.csv IN*.csv > ISIN.csv
	rm IN*.csv

INE INF IN9 IN0 IN1 IN2 IN3 IN4:
	./src/fetch.sh $@

update: ISIN
	echo "::set-output name=version::$(version)"
	sed -i "s/^version.*/version: $(version)/" CITATION.cff
	sed -i "s/^date-released.*/date-released: `date --rfc-3339=date`/" CITATION.cff

	jq ".version = \"$(version)\" | .created = \"`date --rfc-3339=seconds`\"" datapackage.json > d2.json
	mv d2.json datapackage.json
	git add CITATION.cff datapackage.json

# Release Process

old:
	git show HEAD^:ISIN.csv > /tmp/ISIN.csv

release-notes: old
	python3 src/diff.py

release: release-notes
	gh release create "$(version)" --notes-file notes.md ISIN.csv release.md
