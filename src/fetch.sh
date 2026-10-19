#!/bin/bash
set -euo pipefail

API="https://nsdl.com/web/api/v1/participant/search?search_type=DetailedSearch&name="
PER_PAGE=50000
# --fail makes HTTP 4xx/5xx (and WAF error pages) abort loudly instead of feeding jq garbage
CURL_ARGS=(-sS --fail --retry 10 --connect-timeout 30 --retry-max-time 100
  --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36")

RESP=$(mktemp)
trap 'rm -f "$RESP"' EXIT
MAX_TRIES=6
PAGE_DELAY=${PAGE_DELAY:-5}

# NSDL's WAF sometimes answers HTTP 200 with an HTML block page, so retry until jq accepts the body
function api_get() {
  local url="$1" check="$2" try
  for try in $(seq 1 "$MAX_TRIES"); do
    if curl "${CURL_ARGS[@]}" -o "$RESP" "$url" && jq -e "$check" "$RESP" >/dev/null 2>&1; then
      return 0
    fi
    echo "::warning::Bad response (try $try/$MAX_TRIES): $(head -c 200 "$RESP" 2>/dev/null | tr -d '\n')" >&2
    sleep $((try * 15))
  done
  echo "::error::Giving up on $url" >&2
  return 1
}

# Call with INX Page_num file_name
function fetch_page() {
  echo "[+] $1/$2"
  sleep "$PAGE_DELAY"
  api_get "${API}&isin=$1&page=$2&per_page=$PER_PAGE" '.data | type == "array"'
  jq --raw-output '.data[] | [.field_isin, .isin_description__value, .name, .security_description, .isin_status] | map(. // "") | @csv' "$RESP" >> "$3"
}

function fetch_count() {
  # a missing/non-numeric .count is rejected so an API change can't silently become 0 pages
  api_get "${API}&isin=$1&page=1&per_page=1" '.count | tonumber' &&
  jq -r '.count | tonumber' "$RESP"
}

function fetch_class() {
  local class="$1"
  local total="$2"
  local partial="$3"

  if [ "$partial" = "1" ] && [ "$total" -gt 500 ]; then
    # Date-indexed partial fetch: fetch only pages where (page_no % 100) == (day_of_year % 100).
    # All pages get covered every 100 days (~3-4 hits/year on a daily schedule).
    # With per_page=50000 this rarely triggers; it's a guard in case the API caps page size.
    local doy
    doy=$(date +%-j)
    local bucket=$((doy % 100))
    echo "[partial] $class: bucket $bucket/100 (day-of-year $doy)"
    for i in $(seq 1 "$total"); do
      if [ $((i % 100)) -eq "$bucket" ]; then
        fetch_page "$class" "$i" "$class.csv"
      fi
    done
  else
    for i in $(seq 1 "$total"); do
      fetch_page "$class" "$i" "$class.csv"
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

count=$(fetch_count "$CLASS")
total=$(( (count + PER_PAGE - 1) / PER_PAGE ))
echo "::group::$CLASS (Count=$count, Total=$total, partial=$PARTIAL_OK)"
rm -f "$CLASS.csv"
touch "$CLASS.csv" # classes can legitimately have zero results
fetch_class "$CLASS" "$total" "$PARTIAL_OK"
echo "::endgroup::"

# On a full fetch, rows must match the reported count (1% slack for changes
# mid-fetch). Catches a silently capped per_page or dropped pages.
if [ "$PARTIAL_OK" != "1" ] || [ "$total" -le 500 ]; then
  rows=$(wc -l < "$CLASS.csv")
  if [ "$rows" -lt $(( count * 99 / 100 )) ]; then
    echo "::error::$CLASS: fetched $rows rows but API reports count=$count" >&2
    exit 1
  fi
fi

# Sort the file in place
sort -o "$CLASS.csv" "$CLASS.csv"
# Remove lines that don't start with the correct prefix
# This is to avoid ISINs like INF955L01IN9 showing up under IN9
# Note that there is a " at the beginning to account for quoted CSVs
sed "/^\"$CLASS/!d" "$CLASS.csv" > "$CLASS.tmp" && mv "$CLASS.tmp" "$CLASS.csv"
