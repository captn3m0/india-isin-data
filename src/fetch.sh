#!/bin/bash

export PUP_BINARY="$(which pup)"

if ! command -v pup &> /dev/null
then
  wget --quiet https://github.com/ericchiang/pup/releases/download/v0.4.0/pup_v0.4.0_linux_amd64.zip -O pup.zip
  echo "ec3d29e9fb375b87ac492c8b546ad6be84b0c0b49dab7ff4c6b582eac71ba01c  pup.zip" | sha256sum --strict --check
  unzip -o pup.zip
  rm pup.zip
  chmod +x ./pup
  export PUP_BINARY="$(pwd)/pup"
fi

# Call with INX Page_num file_name
function fetch_page() {
  echo "[+] $1/$2"
  curl "https://nsdl.co.in/master_search_res.php" \
    --no-progress-meter \
    --user-agent "Mozilla/Gecko/Firefox/58.0" \
    --retry 10 \
    --connect-timeout 30 \
    --cacert src/GeoTrustTLSRSACAG1.crt.pem \
    --retry-max-time 100 \
    --data cnum=$1 \
    --data "page_no=$2" | \
  $PUP_BINARY '#nsdl-tables tr json{}' | \
  # Generate a CSV (this contains the header row as well)
  jq --raw-output '.[] | [.children[1].children[0].text, .children[2].text, .children[3].text,.children[4].text,.children[5].text]|@csv' | \
  # Convert &amp; to &
  sed 's/&amp;/\&/g' | \
  # Drop the first row
  tail -n +2 >> "$3"
}
function fetch_total_pages() {
  # https://whatsmychaincert.com/?nsdl.co.in 
  # NSDL.co.in is missing the intermediate chain cert
  # so we allow the intermediate (src/GeoTrustTLSRSACAG1.crt.pem)
  curl "https://nsdl.co.in/master_search_res.php" \
    --user-agent "Mozilla/Gecko/Firefox/58.0" \
    --silent \
    --cacert src/GeoTrustTLSRSACAG1.crt.pem \
    --data cnum=$1 \
    --data "page_no=1" |
  $PUP_BINARY 'input[name=total_page] attr{value}'
}
export -f fetch_page

function fetch_class() {
  for i in $(seq 1 $2); do
    sem -j 10 --timeout 500% fetch_page $1 $i "$1.csv"
  done
}

CLASS="$1"

total=$(fetch_total_pages "$CLASS")
echo "::group::$CLASS (Total=$total)"
rm -f "$CLASS.csv"
fetch_class "$CLASS" $total
echo "::endgroup::"

sem --wait

# Sort the file in place
sort -o "$CLASS.csv" "$CLASS.csv"
# Remove lines that don't start with the correct prefix
# This is to avoid ISINs like INF955L01IN9 showing up under IN9
# Note that there is a " at the beginning to account for quoted CSVs
sed -i "/^\"$CLASS/!d" "$CLASS.csv"
