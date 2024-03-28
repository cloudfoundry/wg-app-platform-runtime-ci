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
  
  mkdir -p "repo/${DIR}/.github"
  cp -r ci/shared/github/issue-bug.yml "repo/${DIR}/.github/ISSUE_TEMPLATE"
  cp -r ci/shared/github/issue-enhance.yml "repo/${DIR}/.github/ISSUE_TEMPLATE"
  cp -r ci/shared/github/config.yml "repo/${DIR}/.github/ISSUE_TEMPLATE"
  cp -r ci/shared/github/PULL_REQUEST_TEMPLATE.md "repo/${DIR}/.github"

  if [[ $(git status --porcelain) ]]; then
    git add -A .
    git commit -m "Sync shared github issue/PR templates"
  fi

  rsync -a $PWD/repo "$CURRENT_DIR/synced-repo"
}

trap 'err_reporter $LINENO' ERR
run "$@"
