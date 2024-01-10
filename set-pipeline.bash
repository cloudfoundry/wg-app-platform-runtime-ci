#!/bin/bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
. "${DIR}/shared/helpers/fly-functions.bash"
export -f fly_login
export -f fly_pipeline

export FLY_TARGET=runtime

main() {
  local repo=${1:?Provide a repo e.g. shared,silk-release }
  if [[ ! -d "$DIR/$repo" ]]; then
    echo "$DIR/$repo doesn't exist."
    exit 1
  fi
  "$DIR/$repo/set-repo-pipeline.bash"
}

main "$@"
