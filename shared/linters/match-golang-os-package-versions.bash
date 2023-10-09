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

  local linux_go_version windows_go_version
  linux_go_version=$(get_go_version_for_release "$repo_path" "golang-*linux")
  windows_go_version=$(get_go_version_for_release "$repo_path" "golang-*windows")

  if [[ -n "$linux_go_version" ]] &&  [[ -n "$windows_go_version" ]] && [[ "$linux_go_version" != "$windows_go_version" ]]; then
    echo "Go versions for linux (${linux_go_version}) and windows (${windows_go_version}) do not match."
    if [[ "$exit_on_error" == "true" ]]; then
      exit 1
    fi
  fi
}

run "$@"
