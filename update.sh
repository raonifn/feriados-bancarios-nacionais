#!/bin/bash -e

dir=$(dirname $0)

mkdir -p $dir/build $dir/jsons

function fetch {
  curl https://www.anbima.com.br/feriados/arqs/feriados_nacionais.xls -o $dir/build/feriados.xls

  #from gnumeric
  ssconvert $dir/build/feriados.xls $dir/build/feriados.csv
  grep '^20' $dir/build/feriados.csv \
    | tr -d '"' \
    | jq -Rc 'split(",") | {"year":.[0]|strptime("%Y/%m/%d")|.[0],"date":.[0],"description":.[2]}' \
    | jq -sc 'group_by(.year)[]' \
    > $dir/build/feriados.json
  }

function split {
  while read line; do
    year=$(echo -n $line | jq '.[0].year')
    echo $year
  done < $dir/build/feriados.json
}

# fetch
split
