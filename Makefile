SHELL=/bin/bash
version=`date +%Y.%-m.%-d`

all: INE INF IN9 update
INE INF IN9:
	./fetch.sh $@

update:
	echo "::set-output name=version::$(version)"
	sed -i "s/^version.*/version: $(version)/" CITATION.cff
	sed -i "s/^date-released.*/date-released: `date --rfc-3339=date`/" CITATION.cff

	jq ".version = \"$(version)\" | .created = \"`date --rfc-3339=seconds`\"" datapackage.json > d2.json
	mv d2.json datapackage.json
	git add CITATION.cff datapackage.json