#!/bin/bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
REPO="$DIR/.."
FLY_TEAM=wg-arp-garden

main() {
  local pipeline_dir="$(realpath $REPO/pipelines)"
  fly_login
  fly_pipeline garden-runc-release -f "${pipeline_dir}/garden-runc-release.yml" \
    -f "$REPO/index.yml" \
    -f "$REPO/../shared/helpers/ytt-helpers.star"

  fly_pipeline garden-docker-images -f "${pipeline_dir}/garden-docker-images.yml"
}

main
