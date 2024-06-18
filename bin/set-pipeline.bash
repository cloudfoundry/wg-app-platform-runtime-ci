#!/bin/bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
OSS_CI="$DIR/.."
. "${OSS_CI}/shared/helpers/fly-functions.bash"
export -f fly_login
export -f fly_pipeline

main() {
  local repo=${1:?Provide a repo e.g. shared,cf-networking-release}
  if [[ "$repo" == "all" ]]; then
    local pipelines=$(find "$OSS_CI" -name "set-repo-pipeline.bash")
    for p in ${pipelines}; do
      eval "$p"
    done
  else
    repo_pipeline ${repo}
  fi
}

repo_pipeline() {
  local repo="${1:?Provide a repo name}"
  local ci_config
  if [[ "${PRIVATE_CI:-empty}" == "empty" ]]; then
    ci_config="${OSS_CI}"
  else
    ci_config="${PRIVATE_CI}"
  fi
  if [[ ! -d "$ci_config/$repo" ]]; then
    echo "$ci_config/$repo doesn't exist."
    exit 1
  fi
  "$ci_config/$repo/bin/set-repo-pipeline.bash"
}

main "$@"
