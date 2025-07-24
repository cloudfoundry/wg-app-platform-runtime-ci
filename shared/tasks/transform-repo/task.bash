#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
export CI_DIR="$THIS_FILE_DIR/../../.."
export BUILD_ROOT_DIR="${CI_DIR}/.."
unset THIS_FILE_DIR

function run(){
    local task_tmp_dir="${1:?provide temp dir for task}"
    shift 1

    local TRANSFORMED_REPO_DIR="$PWD/transformed-repo"

    local env_file="$(mktemp -p ${task_tmp_dir} -t 'XXXXX-env.bash')"
    expand_envs "${env_file}"
    . "${env_file}"

    path=${PATH}
    pushd "repo/$DIR"  > /dev/null

    eval "${EVAL_CMD}"

    if [[ $(git status --porcelain) ]]; then
        git add -A .
        git commit -m "${GIT_MESSAGE:-Update repo}"
    fi

    rsync -a $PWD/ "$TRANSFORMED_REPO_DIR"

    popd  > /dev/null
}

function cleanup() {
    rm -rf $task_tmp_dir
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run $task_tmp_dir "$@"
