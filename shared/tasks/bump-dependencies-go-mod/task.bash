#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR
init_git_author

: "GO_MODS: ${GO_MODS:?Need to set GO_MODS}"

export CURRENT_DIR="$PWD"

# This is work around --buildvcs issues in Go 1.18+
git config --global --add safe.directory '*'

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
  pushd repo > /dev/null

  git submodule update --remote --recursive
  if [[ $(git status --porcelain) ]]; then
    git add -A .
    ./scripts/commit-with-submodule-log
  fi

  for entry in ${GO_MODS}
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

  ./scripts/sync-package-specs || true
  if [[ $(git status --porcelain) ]]; then
    git add -A .
    git commit -m "Sync package specs"
  fi

  rsync -av $PWD/ "$CURRENT_DIR/bumped-repo"
  popd > /dev/null
}

process_replace_directives
trap 'err_reporter $LINENO' ERR
run "$@"
