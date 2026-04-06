#!/bin/bash
# @AI-Generated
# Generated in whole or in part by Cursor with a mix of different LLM models (Auto select mode)
# Description:
# 2026-04-06: Render diego-docker-images with ytt + diego-release/index.yml

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
REPO="$DIR/.."
FLY_TEAM=wg-arp-diego

main() {
  local pipeline_dir="$(realpath $REPO/pipelines)"
  fly_login
  fly_pipeline diego-release -f "${pipeline_dir}/diego-release.yml" \
    -f "$REPO/index.yml" \
    -f "$REPO/../shared/helpers/ytt-helpers.star"

  fly_pipeline diego-docker-images -f "${pipeline_dir}/diego-docker-images.yml" \
    -f "$REPO/index.yml"
}

main
