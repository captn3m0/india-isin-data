#!/bin/bash
# Call with INX Page_num file_name
function fetch_page() {
  echo "[+] Fetching Page $2"
  curl "https://nsdl.co.in/master_search_res.php" \
    --silent \
    --data cnum=$1 \
    --data "page_no=$2" |
  ~/bin/pup '#nsdl-tables td text{}'  | paste -d, - - - - - - >> "$3"
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
    sem -j 10 --timeout 300% fetch_page $1 $i "$1.csv"
  done
}

for i in A B E F 9; do
  total=$(fetch_total_pages "IN$i")
  fetch_class "IN$i" $total
done

sem --wait