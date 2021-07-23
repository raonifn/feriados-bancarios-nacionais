#!/bin/bash -e

dir=$(dirname $0)

mkdir -p $dir/build $dir/jsons

function fetch {
  curl -s https://www.anbima.com.br/feriados/arqs/feriados_nacionais.xls -o $dir/build/feriados.xls

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
    echo -n "$year - "
    echo -n $line | jq > $dir/jsons/$year.json
  done < $dir/build/feriados.json
  echo
}

function publish {
  git add jsons
  git commit -m 'Updating' || true
  git push

  tmp=$(mktemp -d)
  cp -r jsons $tmp

  git checkout gh-pages
  mkdir -p $dir/feriados
  cp $tmp/* $dir/feriados

  git add feriados
  git commit -m 'Updating' || true
  git push

  git checkout master

}

echo 'Fetching data from anbima'
# fetch

echo 'Splitting data groupped by year'
# split

echo 'Publishing to Pages'
publish
