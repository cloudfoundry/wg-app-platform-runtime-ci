#!/bin/bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FLY_TEAM=shared

main() {
  local pipeline_dir="$(realpath $DIR/pipelines)"
  fly_login

  fly_pipeline "docker-images" -f "${pipeline_dir}/docker-images.yml"

  fly_pipeline "concourse-maintenance" -f "${pipeline_dir}/update-concourse.yml"

  fly_pipeline "linters" -f "${pipeline_dir}/linters.yml"
}

main
