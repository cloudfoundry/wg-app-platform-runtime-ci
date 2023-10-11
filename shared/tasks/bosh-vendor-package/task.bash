#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TASK_NAME="$(basename "$THIS_FILE_DIR")"
export TASK_NAME
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

  vendored_package_name=$PACKAGE_NAME
  if [[ -n "${PACKAGE_PREFIX}" ]]; then
    vendored_package_name="${PACKAGE_PREFIX}-${PACKAGE_NAME}"
  fi

  ACTUAL_PACKAGE_NAME=$(basename "packages/$PACKAGE_NAME") # resolve globs in PACKAGE_NAME
  if [ -f "packages/${vendored_package_name}/spec.lock" ]; then
    for dep in $(cat "packages/${vendored_package_name}/spec.lock" | yq -r .dependencies[]); do
      echo "cleaning up dependency ${dep}"
      rm -rf "packages/${dep}"
    done
  fi

  debug "bosh vendor for package: ${ACTUAL_PACKAGE_NAME} and prefix: ${PACKAGE_PREFIX}"

  if [[ -n "${PACKAGE_PREFIX}" ]]; then
    bosh vendor-package "${ACTUAL_PACKAGE_NAME}" ../package-release --prefix "${PACKAGE_PREFIX}"
  else
    bosh vendor-package "${ACTUAL_PACKAGE_NAME}" ../package-release
  fi

  if [[ -n $(git status --porcelain) ]]; then
    echo "changes detected, will commit..."
    git add --all
    message="Upgrade ${ACTUAL_PACKAGE_NAME}"

    if [[ -x ../package-release/scripts/get-package-version.sh ]]; then
      fingerprint="$(yq .fingerprint < "packages/${vendored_package_name}/spec.lock")"
      pkg_version=$(cd ../package-release && ./scripts/get-package-version.sh "${fingerprint}" "${ACTUAL_PACKAGE_NAME}")
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
