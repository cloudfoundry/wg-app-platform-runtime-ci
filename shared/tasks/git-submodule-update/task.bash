#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/git-helpers.bash"
unset THIS_FILE_DIR

function git_sudmodule_update() {
    git submodule sync --recursive && \
    git submodule foreach --recursive git submodule sync && \
    git submodule update --init --recursive
}

function run(){
    git_configure_author
    git_configure_safe_directory

    pushd repo > /dev/null
        git_sudmodule_update
        git clean -ffd
    popd > /dev/null
}

trap 'err_reporter $LINENO' ERR
run "$@"
