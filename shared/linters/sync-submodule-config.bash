#!/bin/bash

set -eu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../shared/helpers/git-helpers.bash"
unset THIS_FILE_DIR

function run() {
  local repo_path=${1:?Provide a path to the repository}
  local exit_on_error=${2:-"false"}

  pushd $repo_path > /dev/null
  local submodules=$(git submodule)
  if [[ -z "$submodules" ]]; then
    echo "No submodule for this repo, intentionally left blank"
  fi
  popd > /dev/null

  if [[ -n "$submodules" ]] && [[ "$exit_on_error" == "true" ]]; then
    echo "Found submodule for this repo without sync-submodule-config.bash"
    exit 1
  fi


}

verify_binary gosub
run "$@"
