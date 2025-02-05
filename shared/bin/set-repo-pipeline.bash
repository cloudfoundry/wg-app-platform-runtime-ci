#!/bin/bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
REPO="$DIR/.."
FLY_TEAM=shared

main() {
  local pipeline_dir="$(realpath $REPO/pipelines)"
  fly_login

  fly_pipeline "shared-docker-images" -f "${pipeline_dir}/shared-docker-images.yml"

  fly_pipeline "linters" -f "${pipeline_dir}/linters.yml"
}

main
