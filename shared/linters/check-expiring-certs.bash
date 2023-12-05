#!/bin/bash

set -eu
set -o pipefail

function expired_in() {
  local cert="${1:?Provide a cert}"
  local how_many_days="${2:?How many days}"
  local expires_in=$(openssl x509 -in ${cert} -noout -dates 2> /dev/null | grep notAfter | cut -d'=' -f2 | xargs -I{} date -d {} +%s)
  local after=$(date -d "+${how_many_days} days" +%s)
  if [ ! -z "$expires_in" ] && [ $expires_in -le $after ];
  then
    echo "failed"
  fi
}

function run() {
  local repo_path=${1:?Provide a path to the repository}

  pushd $repo_path > /dev/null
  echo "Checking for expiring certs..."
  local found=false
  for i in $(find . -name *.crt); do
    local failed=$(expired_in "$i" 60)
    if [ ! -z "${failed}" ]; then
      found="true"
      echo "$i expiring in 60 days"
    fi
  done
  popd > /dev/null

  if [ "$found" == "true" ]; then
    echo "Found certs expiring in 60 days:"
    exit 1
  fi

}

run "$@"
