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
  curl --insecure "https://nsdl.co.in/master_search_res.php" \
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
  curl --insecure "https://nsdl.co.in/master_search_res.php" \
    --user-agent "Mozilla/Gecko/Firefox/58.0" \
    --silent \
    --cacert src/GeoTrustTLSRSACAG1.crt.pem \
    --data cnum=$1 \
    --data "page_no=1" |
  $PUP_BINARY 'input[name=total_page] attr{value}'
}
export -f fetch_page

function fetch_class() {
  local class="$1"
  local total="$2"
  local partial="$3"

  if [ "$partial" = "1" ] && [ "$total" -gt 500 ]; then
    # Date-indexed partial fetch: fetch only pages where (page_no % 100) == (day_of_year % 100).
    # All pages get covered every 100 days (~3-4 hits/year on a daily schedule).
    local doy
    doy=$(date +%-j)
    local bucket=$((doy % 100))
    echo "[partial] $class: bucket $bucket/100 (day-of-year $doy)"
    for i in $(seq 1 "$total"); do
      if [ $((i % 100)) -eq "$bucket" ]; then
        sem -j 10 --timeout 500% fetch_page "$class" "$i" "$class.csv"
      fi
    done
  else
    for i in $(seq 1 "$total"); do
      sem -j 10 --timeout 500% fetch_page "$class" "$i" "$class.csv"
    done
  fi
}

PARTIAL_OK=0
CLASS=""
for arg in "$@"; do
  case "$arg" in
    --partial-okay) PARTIAL_OK=1 ;;
    *) CLASS="$arg" ;;
  esac
done
if [ -z "$CLASS" ]; then
  echo "Usage: $0 [--partial-okay] CLASS" >&2
  exit 1
fi

total=$(fetch_total_pages "$CLASS")
echo "::group::$CLASS (Total=$total, partial=$PARTIAL_OK)"
rm -f "$CLASS.csv"
fetch_class "$CLASS" "$total" "$PARTIAL_OK"
echo "::endgroup::"

sem --wait

# Sort the file in place
sort -o "$CLASS.csv" "$CLASS.csv"
# Remove lines that don't start with the correct prefix
# This is to avoid ISINs like INF955L01IN9 showing up under IN9
# Note that there is a " at the beginning to account for quoted CSVs
sed -i "/^\"$CLASS/!d" "$CLASS.csv"
