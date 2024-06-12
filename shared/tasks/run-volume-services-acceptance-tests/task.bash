#!/bin/bash

set -ex

if [[ -z "${CONFIG_FILE_PATH}" ]]; then
  echo "Missing required CONFIG_FILE_PATH parameter."
  exit 1
fi

export CONFIG="${PWD}/${CONFIG_FILE_PATH}"

pushd cf-volume-services-acceptance-tests
  if [[ -n "${PARALLEL_NODES}" ]]; then
    ./bin/test --flake-attempts 3 --slow-spec-threshold 300s --nodes "${PARALLEL_NODES}" .
  else
    ./bin/test --flake-attempts 3 --slow-spec-threshold 300s -p .
  fi
popd
