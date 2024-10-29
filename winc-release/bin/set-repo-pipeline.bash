#!/bin/bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
REPO="$DIR/.."
FLY_TEAM=wg-arp-garden

main() {
  local pipeline_dir="$(realpath $REPO/pipelines)"
  fly_login
  # fly_pipeline winc-release -f "${pipeline_dir}/winc-release.yml" \
  fly_pipeline winc-shepherd -f "${pipeline_dir}/winc-shepherd.yml" \
    -f "$REPO/index.yml" \
    -f "$REPO/../shared/helpers/ytt-helpers.star"

  fly_pipeline winc-docker-images -f "${pipeline_dir}/winc-docker-images.yml"
}

main
