#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/cf-helpers.bash"
unset THIS_FILE_DIR

function run(){

  VERSION=$(cat ./version/number)
  if [ -z "$VERSION" ]; then
    echo "missing version number"
    exit 1
  fi

  pushd repo > /dev/null

  git remote add release-repo ../release-repo
  git fetch release-repo

  if [[ -n "$(git tag | grep -E "^v${VERSION}$")" ]]; then
    echo "git tag ${VERSION} already exists. Nothing has been tagged or commited. Fast failing..."
    exit 1
  fi

  if [[ -n "$(git rev-list HEAD..release-repo/release)" ]]; then
    echo "Release branch contains commits not on HEAD. Nothing has been tagged or commited. Fast failing..."
    exit 1
  fi

  popd > /dev/null
}

trap 'err_reporter $LINENO' ERR
run "$@"
