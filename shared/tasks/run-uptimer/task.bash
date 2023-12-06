#!/bin/bash

set -eEu
set -o pipefail

function run() {
  local config="$(ls config/uptimer*.json)"
  uptimer -configFile "$config"
}

run "$@"
