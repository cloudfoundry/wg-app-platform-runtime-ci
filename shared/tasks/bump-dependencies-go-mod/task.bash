#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/git-helpers.bash"
unset THIS_FILE_DIR

export CURRENT_DIR="$PWD"

function git_diff_pretty() {
  echo "Update go.mod dependencies"
  echo ""
  echo "--------"
  echo ""
  git diff --cached $1 | grep -Ev 'indirect|require|\)|go\.mod'
}

function process_replace_directives() {
  for entry in ${REPLACE_DIRECTIVES}
  do
    src=$(echo $entry | cut -d ":" -f1)
    dest=$(echo $entry | cut -d ":" -f2)
    ls "$src"
    ln -s "$src" "$dest"
  done
  
}
function bump() {
  local tag="${1:-}"
  export GOFLAGS="-tags=$tag"
  go get -t -u ./...
  go mod tidy
  go mod vendor
  unset GOFLAGS
  go vet ./...
}

function run() {
  local task_tmp_dir="${1:?provide temp dir for task}"
  shift 1
  git_configure_author
  git_configure_safe_directory

  if [[ -d "built-binaries" ]]; then
    IFS=$'\n'
    for entry in $(find built-binaries -name "*.bash");
    do
      echo "Sourcing: $entry"
      debug "$(cat $entry)"
      source "${entry}"
    done
    unset IFS
  fi
  
  local env_file="$(mktemp -p ${task_tmp_dir} -t 'XXXXX-env.bash')"
  expand_envs "${env_file}"
  . "${env_file}"

  pushd repo > /dev/null
  local repo_name=$(git_get_remote_name)

  git_fetch_latest_submodules
  if [[ $(git status --porcelain) ]]; then
    git add -A .
    git_commit_with_submodule_log
  fi

  expand_functions

  for entry in ${GO_MODS:-}
  do

    dir_name=$(dirname "$entry")
    go_mod=$(basename "$entry")

    echo "---Updating go-mod dependencies for ${dir_name}"

    echo "$dir_name"
    pushd "$dir_name" > /dev/null

    #update dependencies (avoids submodules)
    bump
    for go_build_tag in ${EXTRA_GO_TAGS}
    do
      bump "${go_build_tag}"
    done

    if [[ $(git status --porcelain) ]]; then
      git add -A .
      git commit -F <(git_diff_pretty $go_mod)
    fi

    popd > /dev/null
  done

  if [[ -f "../ci/${repo_name}/linters/sync-package-specs.bash" ]]; then
    "../ci/${repo_name}/linters/sync-package-specs.bash" ${PWD}
  fi

  if [[ $(git status --porcelain) ]]; then
    git add -A .
    git commit -m "Sync package specs"
  fi

  rsync -av $PWD/ "$CURRENT_DIR/bumped-repo"
  popd > /dev/null
}
function cleanup() {
    rm -rf $task_tmp_dir
}

process_replace_directives
task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run $task_tmp_dir "$@"
