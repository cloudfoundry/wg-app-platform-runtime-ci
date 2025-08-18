#!/bin/bash

function run() {
  local repo_path=${1:?Provide a path to the repository}

  routing_api_version=70020201ed76f98cd276ad094b687cf73cc2dd04
  guardian_version=ef3063efe1fe24dcbe1bc239489286c8e958c0b4

  pushd "${repo_path}" > /dev/null
  pushd src/code.cloudfoundry.org/routing-api > /dev/null
  echo "Checking out ${routing_api_version} routing-api"
  git checkout $routing_api_version
  popd > /dev/null
  pushd src/guardian > /dev/null
  echo "Checking out ${guardian_version} guardian"
  git checkout $guardian_version
  popd > /dev/null
  popd > /dev/null
}

run "$@"
