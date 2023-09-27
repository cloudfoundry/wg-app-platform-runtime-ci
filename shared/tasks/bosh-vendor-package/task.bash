#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TASK_NAME="$(basename "$THIS_FILE_DIR")"
export TASK_NAME
PACKAGE_NAME="$(cat package-name/name)"
export PACKAGE_NAME
OLD_PACKAGE_NAME="$(cat package-name/old-name)"
export OLD_PACKAGE_NAME
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/git-helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"
unset THIS_FILE_DIR

function run() {
  git_configure_author
  git_configure_safe_directory

  pushd repo > /dev/null
  local private_yml="./config/private.yml"
  bosh_configure_private_yml $private_yml

  debug "bosh vendor for package: ${PACKAGE_NAME} and prefix: ${PACKAGE_PREFIX}"

  if [[ -n "${PACKAGE_PREFIX}" ]]; then
    bosh vendor-package "${PACKAGE_NAME}" ../package-release --prefix "${PACKAGE_PREFIX}"
  else
    bosh vendor-package "${PACKAGE_NAME}" ../package-release
  fi

  if [[ -n "${OLD_PACKAGE_NAME}" ]] && [[ "${OLD_PACKAGE_NAME}" != "${PACKAGE_NAME}" ]]; then
    rm -rf packages/"${OLD_PACKAGE_NAME}"
    sed -i "s/${OLD_PACKAGE_NAME}/${PACKAGE_NAME}/g" packages/**/spec jobs/**/spec
  fi

  if [[ -n $(git status --porcelain) ]]; then
    echo "changes detected, will commit..."
    git add --all
    message="Upgrade ${PACKAGE_NAME}"

    if [[ -x ../package-release/scripts/get-package-version.sh ]]; then
      fingerprint="$(yq .fingerprint < "packages/${PACKAGE_NAME}/spec.lock")"
      pkg_version=$(cd ../package-release && ./scripts/get-package-version.sh "${fingerprint}" "${PACKAGE_NAME}")
      message="${message} (${pkg_version})"
    fi
    git commit -m "${message}"

    git log -1 --color | cat
  else
    echo "no changes in repo, no commit necessary"
  fi

  cp -r . ../vendored-repo/
  popd > /dev/null
}

trap 'err_reporter $LINENO' ERR
run "$@"
