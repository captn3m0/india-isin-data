# India ISIN Data

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.6508187.svg)](https://doi.org/10.5281/zenodo.6508187) ![GitHub release (latest by date)](https://img.shields.io/github/v/release/captn3m0/india-isin-data) ![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/captn3m0/india-isin-data) ![GitHub repo size](https://img.shields.io/github/repo-size/captn3m0/india-isin-data)

ISIN Data from various public securities.

Source: [NSDL Website Detailed ISIN Search][nsdl].

Automatically updated every midnight (IST).

|File|Issuer|Tracked|
-----|-----|----|
`INA.csv`|Central Government|No
`INB.csv`|State Government|No
`INE.csv`|Company, Statuatory Corporation, Banking Company|Yes
`INF.csv`|Mutual Funds|Yes
`IN9.csv`|Partly paid up shares|Yes

**Note**: The [NSDL Website][nsdl] returns zero valid results for `INA, INB`, so those are not tracked.

# Code

You can run the `fetch.sh` script to generate the tracked the files from scratch. Dependencies:

- https://github.com/ericchiang/pup
- https://stedolan.github.io/jq/
- https://www.gnu.org/software/parallel/
- https://curl.se/
- https://www.gnu.org/software/sed/

# Structure

- https://www.basunivesh.com/how-your-dmat-mutual-funds-and-shares-isin-structured/
- https://theindianstockbrokers.com/what-is-isin-number-and-how-to-find-it/


# Alternative Sources

- https://nsdl.co.in/downloadables/html/hold-mutual-fund-units.html
- [The Kuvera Mutual Fund Details API](https://stoplight.captnemo.in/docs/kuvera/reference/Kuvera.yaml/paths/~1mf~1api~1v4~1fund_schemes~1%7Bcodes%7D.json/get) returns ISIN codes.

# License

Licensed under the [Creative Commons Zero v1.0 Universal](LICENSE) license. There are no guarantees made as to the correctness or accuracy of this data.

[nsdl]: https://nsdl.co.in/master_search.php
