#!/bin/bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
REPO="$DIR/.."
FLY_TEAM=wg-arp-garden

main() {
  local pipeline_dir="$(realpath $REPO/pipelines)"
  fly_login
  fly_pipeline windows2016fs -f "${pipeline_dir}/windows2016fs.yml" \
    -f "$REPO/../shared/helpers/ytt-helpers.star"
}

main
