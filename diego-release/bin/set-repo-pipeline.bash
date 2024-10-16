#!/bin/bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
REPO="$DIR/.."
FLY_TEAM=wg-arp-diego

main() {
  local pipeline_dir="$(realpath $REPO/pipelines)"
  fly_login
  fly_pipeline diego-protobuf -f "${pipeline_dir}/diego-protobuf.yml" \
    -f "$REPO/index.yml" \
    -f "$REPO/../shared/helpers/ytt-helpers.star"

  fly_pipeline diego-docker-images -f "${pipeline_dir}/diego-docker-images.yml"
}

main
