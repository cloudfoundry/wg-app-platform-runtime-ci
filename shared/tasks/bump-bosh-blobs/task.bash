#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/git-helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"
unset THIS_FILE_DIR

export CURRENT_DIR="$PWD"

function run() {
  git_configure_author
  git_configure_safe_directory

  pushd blob > /dev/null
  local blob="${PWD}"
  local blob_name=$(git_get_remote_name) #if git repo resource
  if [[ -z "${blob_name}" && -f url ]]; then
    blob_name=$(cat url) #if github release resource
  elif [[ -z "${blob_name}" && -f filename ]]; then
    blob_name=$(cat filename) # if s3 resource
  else
    blob_name=$(ls --format=commas)
  fi
  popd > /dev/null

  pushd repo > /dev/null
  bosh_configure_private_yml "./config/private.yml"
  bosh sync-blobs

  local repo_name=$(git_get_remote_name)

  if [[ -f "../ci/${repo_name}/helpers/bump-bosh-blobs.bash" ]]; then
    "../ci/${repo_name}/helpers/bump-bosh-blobs.bash" "${PWD}" "${BOSH_BLOB_PATH}" "${blob}" 
  fi

  bosh upload-blobs
  rm -rf ./config/private.yml

  if [[ $(git status --porcelain) ]]; then
    git add -A .
    git commit -m "Bump ${blob_name}"
  fi

  rsync -a $PWD/ "$CURRENT_DIR/bumped-repo"
  popd > /dev/null
}

trap 'err_reporter $LINENO' ERR
run "$@"
