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

  local CI_DIR="$PWD/ci"
  local CI_CONFIG_DIR="$PWD/ci-config"

  pushd blob > /dev/null
  local blob="${PWD}"
  local blob_name
  if [[ -f url ]]; then
    blob_name=$(cat url) #if github release resource
  elif [[ -f filename ]]; then
    blob_name=$(cat filename) # if s3 resource
  elif [[ -f version ]]; then
    blob_name="$(dirname ${BOSH_BLOB_PATH}) to $(cat version)" # if gitlab release resource
  elif [[ -d .git ]]; then
    blob_name="$(dirname ${BOSH_BLOB_PATH}) to $(git describe --tags --abbrev=0)" # if git resource
  elif [[ "${blob_name:-empty}" == "empty" ]]; then
    blob_name="$(dirname ${BOSH_BLOB_PATH}) $(ls --format=commas)"
  fi
  popd > /dev/null

  pushd repo > /dev/null
  bosh_configure_private_yml "./config/private.yml"
  bosh sync-blobs 1>/dev/null

  local repo_name=$(git_get_remote_name)
  popd > /dev/null

  local bump_bosh_blobs_filepath_in_ci="${CI_DIR}/${repo_name}/helpers/bump-bosh-blobs.bash"
  local bump_bosh_blobs_filepath_in_ci_config="${CI_CONFIG_DIR}/${repo_name}/helpers/bump-bosh-blobs.bash"
  if [[ -f "${bump_bosh_blobs_filepath_in_ci}" ]]; then
    "${bump_bosh_blobs_filepath_in_ci}" "${PWD}/repo" "${BOSH_BLOB_PATH}" "${blob}"
  elif [[ -f "${bump_bosh_blobs_filepath_in_ci_config}" ]]; then
    "${bump_bosh_blobs_filepath_in_ci_config}" "${PWD}/repo" "${BOSH_BLOB_PATH}" "${blob}"
  else
    echo "🔥 Can't find ${bump_bosh_blobs_filepath_in_ci} or ${bump_bosh_blobs_filepath_in_ci_config}"
    exit 1
  fi

  pushd repo > /dev/null
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
