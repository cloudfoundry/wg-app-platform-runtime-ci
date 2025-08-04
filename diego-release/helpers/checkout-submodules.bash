#!/bin/bash

function run() {
  local repo_path=${1:?Provide a path to the repository}

  routing_api_version=70020201ed76f98cd276ad094b687cf73cc2dd04

  pushd "${repo_path}" > /dev/null
  pushd src/routing-api > /dev/null
  echo "Checking out ${routing_api_version} routing-api"
  git checkout $routing_api_version
  popd > /dev/null
  popd > /dev/null
}

run "$@"
