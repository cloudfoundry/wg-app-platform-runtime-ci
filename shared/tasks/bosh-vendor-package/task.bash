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

  package_name=$(basename packages/${vendored_package_name})

  if [ -f "packages/${package_name}/spec.lock" ]; then
    for dep in $(yq -r ".dependencies[]?" "packages/${package_name}/spec.lock"); do
      rm -rf "packages/${dep}"
    done
  fi

  debug "bosh vendor for package: ${package_name} and prefix: ${PACKAGE_PREFIX}"

  if [[ -n "${PACKAGE_PREFIX}" ]]; then
    bosh vendor-package "${PACKAGE_NAME}" ../package-release --prefix "${PACKAGE_PREFIX}"
  else
    bosh vendor-package "${package_name}" ../package-release
  fi

  if [[ -n $(git status --porcelain) ]]; then
    echo "changes detected, will commit..."
    git add --all
    message="Upgrade ${package_name}"

    if [[ -x ../package-release/scripts/get-package-version.sh ]]; then
      fingerprint="$(yq -r .fingerprint < "packages/${package_name}/spec.lock")"
      pkg_version=$(cd ../package-release && ./scripts/get-package-version.sh "${fingerprint}" "${package_name}")
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
