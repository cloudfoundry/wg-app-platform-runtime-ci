#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"
unset THIS_FILE_DIR

function run() {
  init_git_author

  pushd repo > /dev/null
  local private_yml="./config/private.yml"
  bosh_configure_private_yml $private_yml

  debug "bosh vendor for package: ${PACKAGE_NAME} and prefix: ${PACKAGE_PREFIX}"

  if [[ -n "${PACKAGE_PREFIX}" ]]; then
    bosh vendor-package "${PACKAGE_NAME}" ../package-release --prefix "${PACKAGE_PREFIX}"
  else
    bosh vendor-package "${PACKAGE_NAME}" ../package-release
  fi

  if [[ -n $(git status --porcelain) ]]; then
    echo "changes detected, will commit..."
    git add --all
    git commit -m "Upgrade ${PACKAGE_NAME}"

    git log -1 --color | cat
  else
    echo "no changes in repo, no commit necessary"
  fi

  cp -r . ../vendored-repo/
  popd > /dev/null
}

trap 'err_reporter $LINENO' ERR
run "$@"
