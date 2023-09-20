#!/bin/bash

set -eu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../shared/helpers/git-helpers.bash"
unset THIS_FILE_DIR

function run() {
    local repo_path=${1:?Provide a path to the repository}
    local exit_on_error=${2:-"false"}

    pushd "${repo_path}" > /dev/null

    sync_package healthchecker       -app code.cloudfoundry.org/healthchecker/... &

    wait

    git diff --name-only packages/*/spec

    if [[ "$exit_on_error" == "true" ]]; then
      git_error_when_diff
    fi

    popd > /dev/null
}

function sync_package() {
  bosh_pkg=${1}

  shift

  (
    set -e

    cd src/code.cloudfoundry.org

    spec=../../packages/${bosh_pkg}/spec

    {
      cat $spec | grep -v '# gosub'

      for package in $(gosub list "$@"); do
        repo=$(echo ${2} | cut -f1-3 -d/)
        if [ -d "../../src/code.cloudfoundry.org/vendor/${package}" ]; then
          package="code.cloudfoundry.org/vendor/${package}"
        fi
        echo ${package} | sed -e 's/\(.*\)/  - \1\/*.go # gosub/g'
        if ls ../../src/${package}/*.s >/dev/null 2>&1; then
          echo ${package} | sed -e 's/\(.*\)/  - \1\/*.s # gosub/g'
        fi
        if ls ../../src/${package}/*.h >/dev/null 2>&1; then
          echo ${package} | sed -e 's/\(.*\)/  - \1\/*.h # gosub/g'
        fi
      done
    } > $spec.new

    mv $spec.new $spec
  )
}


verify_binary gosub
run "$@"
