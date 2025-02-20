#!/bin/bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
REPO="$DIR/.."
FLY_TEAM=wg-arp-networking

main() {
  local pipeline_dir="$(realpath $REPO/pipelines)"
  fly_login
  fly_pipeline cf-networking-protobuf -f "${pipeline_dir}/cf-networking-protobuf.yml" \
    -f "$REPO/index.yml" \
    -f "$REPO/../silk-release/index.yml" \
    -f "$REPO/../shared/helpers/ytt-helpers.star"
}

main
