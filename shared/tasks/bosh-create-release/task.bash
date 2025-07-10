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
  local version=$(cat ./version/number)
  if [ -z "$version" ]; then
    echo "missing version number"
    exit 1
  fi

  echo "${GCP_BLOBSTORE_SERVICE_ACCOUNT_KEY}" > config/t.key

  pushd repo > /dev/null
  local private_yml="./config/private.yml"
  bosh_configure_private_yml "$private_yml"

  echo "creating release tarball"
  local release_name=$(bosh_release_name)
  echo "release name:" ${release_name}
  bosh -n create-release --version="$version" --tarball  ../created-release-tarball/${release_name}-${version}.tgz
  popd > /dev/null
}

trap 'err_reporter $LINENO' ERR
run "$@"
