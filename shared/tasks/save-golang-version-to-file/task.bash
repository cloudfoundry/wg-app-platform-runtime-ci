#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR

function run(){
  local task_tmp_dir="${1:?provide temp dir for task}"
  shift 1

  init_git_author

  pushd repo > /dev/null

  local release_tarball_path="${task_tmp_dir}/release.tgz"
  bosh create-release --tarball="${release_tarball_path}"
  debug "Created a release tarball: ${release_tarball_path} for $(get_git_remote_name):"

  mkdir -p docs
  local version=$(tar -Oxz "packages/${PACKAGE}.tgz" < "${release_tarball_path}" | tar z --list | grep -ohE 'go[0-9]\.[0-9]{1,2}\.[0-9]{0,2}')
  local date=$(date '+%Y-%m-%d %H:%M:%S')
  echo "This file was updated by CI on ${date}" > docs/go.version
  echo "$version" >> docs/go.version

  if [[ -n $(git status --porcelain) ]]; then
    echo "changes detected, will commit..."
    git add --all
    git commit -m "Update Go version file to ${version}"

    git log -1 --color | cat
  else
    echo "no changes in repo, no commit necessary"
  fi

  cp -r . ../saved-repo/
  popd > /dev/null
}

function cleanup() {
  rm -rf $task_tmp_dir
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run $task_tmp_dir "$@"
