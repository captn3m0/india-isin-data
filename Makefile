SHELL=/bin/bash
version=`date +%Y.%-m.%-d`

all: INE INF IN9 update
INE INF IN9:
	./fetch.sh $@

old:
	git show HEAD^:INE.csv > /tmp/INE.csv
	git show HEAD^:INF.csv > /tmp/INF.csv
	git show HEAD^:IN9.csv > /tmp/IN9.csv

release.md: old
	python3 diff.py > release.md

release: release.md
	gh release create "$(version)" --notes-file release.md IN*.csv

update:
	echo "::set-output name=version::$(version)"
	sed -i "s/^version.*/version: $(version)/" CITATION.cff
	sed -i "s/^date-released.*/date-released: `date --rfc-3339=date`/" CITATION.cff

	jq ".version = \"$(version)\" | .created = \"`date --rfc-3339=seconds`\"" datapackage.json > d2.json
	mv d2.json datapackage.json
	git add CITATION.cff datapackage.json