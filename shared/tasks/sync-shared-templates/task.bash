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
  git_configure_author
  git_configure_safe_directory
 
  pushd repo > /dev/null
  mkdir -p "${DIR}/.github"
  cp -r ../ci/shared/github/issue-bug.yml "${DIR}/.github/ISSUE_TEMPLATE"
  cp -r ../ci/shared/github/issue-enhance.yml "${DIR}/.github/ISSUE_TEMPLATE"
  cp -r ../ci/shared/github/config.yml "${DIR}/.github/ISSUE_TEMPLATE"
  cp -r ../ci/shared/github/PULL_REQUEST_TEMPLATE.md "${DIR}/.github"

  if [[ $(git status --porcelain) ]]; then
    git add -A .
    git commit -m "Sync shared github issue/PR templates"
  fi

  rsync -a $PWD "$CURRENT_DIR/synced-repo"

  popd > /dev/null
}

trap 'err_reporter $LINENO' ERR
run "$@"
