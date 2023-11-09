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

  pushd repo > /dev/null

  bosh sync-blobs
  local old_envoy_version=$(ls -1 blobs/proxy/envoy*.tgz | xargs basename | sed 's/envoy-\(.*\).tgz/\1/g')
  local new_envoy_version=$(../envoy-binary/envoy --version | grep -vE '^$' | awk '{print $3}' | cut -d/ -f1,2 | tr / -)

  if [[ "$old_envoy_version" == "$new_envoy_version" ]]; then
    echo "$new_envoy_version is currently the latest version."
    rsync -av $PWD/ ../bumped-repo
    exit 0
  fi


  bosh remove-blob proxy/envoy-${old_envoy_version}.tgz
  bosh add-blob ../envoy-binary/envoy.tgz proxy/envoy-${new_envoy_version}.tgz
  sed -i "s/envoy.*\.tgz/envoy-${new_envoy_version}\.tgz/g" packages/proxy/*
  bosh blobs
  bosh upload-blobs
  bosh blobs

  git --no-pager diff config/ packages/

  git checkout -b bump-envoy

  git add -A config packages
  git commit -n -m "Bump envoy to $(echo ${new_envoy_version} |  head -c 10)"
  rsync -av $PWD/ ../bumped-repo

  popd > /dev/null
}

trap 'err_reporter $LINENO' ERR
run "$@"
