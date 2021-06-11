#!/bin/bash
# Call with INX Page_num file_name
function fetch_page() {
  echo "[+] $1/$2"
  curl "https://nsdl.co.in/master_search_res.php" \
    --silent \
    --data cnum=$1 \
    --data "page_no=$2" |
  # for each row
  pup '#nsdl-tables tr json{}' | \
  # generate 6 lines (second column has a link, so parse that) with raw output
  jq --raw-output '.[] | [.children[1].children[0].text, .children[2].text, .children[3].text,.children[4].text,.children[5].text]|.[]' | \
  # and create a CSV from every 5 lines
  paste -d, - - - - -  | \
  # and we don't need the first row
  tail -n +2 >> "$3"
}
function fetch_total_pages() {
  curl "https://nsdl.co.in/master_search_res.php" \
    --silent \
    --data cnum=$1 \
    --data "page_no=1" |
  pup 'input[name=total_page] attr{value}'
}
export -f fetch_page

function fetch_class() {
  for i in $(seq 1 $2); do
    sem -j 10 --timeout 500% fetch_page $1 $i "$1.csv"
  done
}

for i in A B E F 9; do
  total=$(fetch_total_pages "IN$i")
  fetch_class "IN$i" $total
done

sem --wait