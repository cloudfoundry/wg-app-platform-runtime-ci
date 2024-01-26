#!/bin/bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
REPO="$DIR/.."
. "${REPO}/shared/helpers/fly-functions.bash"
export -f fly_login
export -f fly_pipeline

main() {
  local repo=${1:?Provide a repo e.g. shared,cf-networking-release}
  if [[ "$repo" == "all" ]]; then
    local pipelines=$(find "$REPO" -name "set-repo-pipeline.bash")
    for p in ${pipelines}; do
      eval "$p"
    done
  else
    repo_pipeline ${repo}
  fi
}

repo_pipeline() {
  if [[ ! -d "$REPO/$repo" ]]; then
    echo "$REPO/$repo doesn't exist."
    exit 1
  fi
  "$REPO/$repo/bin/set-repo-pipeline.bash"
}

main "$@"
