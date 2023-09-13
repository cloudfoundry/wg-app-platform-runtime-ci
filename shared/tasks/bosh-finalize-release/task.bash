#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/git-helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"
unset THIS_FILE_DIR

function run() {
  git_configure_author

  local version=$(cat ./version/number)
  if [ -z "$version" ]; then
    echo "missing version number"
    exit 1
  fi

  pushd repo > /dev/null
  local private_yml="./config/private.yml"
  bosh_configure_private_yml "$private_yml"

  echo "creating final release"
  local release_name="$(yq -r .final_name < ./config/final.yml)"
  echo "release name:" ${release_name}
  bosh -n create-release --final --version="$version" --tarball  ../finalized-release-tarball/${release_name}-${version}.tgz
  git add -A
  git commit -m "Release v${version}"

  cp -r . ../finalized-release-repo/
  popd > /dev/null
}

trap 'err_reporter $LINENO' ERR
run "$@"
