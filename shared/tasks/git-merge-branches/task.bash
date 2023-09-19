#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/git-helpers.bash"
unset THIS_FILE_DIR

function run(){
    git_configure_author
    git_configure_safe_directory

    git clone ./source-branch ./merged-branch

    pushd merged-branch > /dev/null

    git remote add local ../onto-branch
    git fetch local
    git checkout "local/${ONTO_BRANCH_NAME}"

    git merge --no-edit "${SOURCE_BRANCH_NAME}"

    popd > /dev/null
}

trap 'err_reporter $LINENO' ERR
run "$@"
