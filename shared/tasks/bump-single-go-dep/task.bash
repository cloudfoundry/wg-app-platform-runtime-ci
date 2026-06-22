#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/git-helpers.bash"
unset THIS_FILE_DIR

export CURRENT_DIR="$PWD"

function run() {
  local task_tmp_dir="${1:?provide temp dir for task}"
  shift 1

  git_configure_author
  git_configure_safe_directory

  local ver
  ver=$(cat version/number)

  pushd repo > /dev/null

  pushd "${SUBDIR}" > /dev/null
  go get "${MODULE_PATH}@v${ver}"
  go mod tidy
  go mod vendor

  if [[ $(git status --porcelain) ]]; then
    git add -A .
    git commit -m "Bump ${MODULE_PATH} to v${ver}"
  fi
  popd > /dev/null

  rsync -av "${PWD}/" "${CURRENT_DIR}/bumped-repo"
  popd > /dev/null
}

function cleanup() {
  rm -rf "$task_tmp_dir"
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run "$task_tmp_dir" "$@"
