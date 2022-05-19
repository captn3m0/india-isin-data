SHELL=/bin/bash
version=`date +%Y.%-m.%-d`

# Build Process

ISIN: INE INF IN9 IN0 IN1 IN2 IN3 IN4
	cat header.csv IN*.csv > ISIN.csv
	rm IN*.csv

INE INF IN9 IN0 IN1 IN2 IN3 IN4:
	./fetch.sh $@
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

release.md: old
	python3 diff.py > release.md

release: release.md
	gh release create "$(version)" --notes-file release.md ISIN.csv
