#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR

function run(){
    init_git_author
    git config --global --add safe.directory '*'

    local onto_branch_name="$(git -C ./onto-branch rev-parse --abbrev-ref HEAD)"
    local source_branch_name="$(git -C ./source-branch rev-parse --abbrev-ref HEAD)"

    git clone ./source-branch ./merged-branch

    popd merged-branch > /dev/null

    git remote add local ../onto-branch
    git fetch local
    git checkout "local/${onto_branch_name}"

    git merge --no-edit "${source_branch_name}"

    pushd > /dev/null
}

trap 'err_reporter $LINENO' ERR
run "$@"
