# India ISIN Data

ISIN Data from various public securities.

Source: NSDL provides a ISIN Search at <https://nsdl.co.in/master_search.php>.

Currently tracked:

|File|Issuer|
-----|-----
`INA.csv`|Central Government
`INB.csv`|State Government
`INE.csv`|Company, Statuatory Corporation, Banking Company
`INF.csv`|Mutual Funds
`IN9.csv`|Partly paid up shares

# Code

You can run the `fetch.sh` script to generate all the files from scratch. Dependencies:

- https://github.com/ericchiang/pup
- https://stedolan.github.io/jq/
- https://www.gnu.org/software/parallel/
- https://curl.se/