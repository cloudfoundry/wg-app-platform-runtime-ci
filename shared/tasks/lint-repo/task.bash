#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/git-helpers.bash"
if [[ -n "${DEFAULT_PARAMS:-}" ]] && [[ -f "${DEFAULT_PARAMS}" ]]; then
    debug "extract-default-params-for-task with values from ${DEFAULT_PARAMS}"
    . <("$THIS_FILE_DIR/../../../shared/helpers/extract-default-params-for-task.bash" "${DEFAULT_PARAMS}")
fi
unset THIS_FILE_DIR

function run(){
    local task_tmp_dir="${1:?provide temp dir for task}"
    shift 1

    git_configure_safe_directory

    pushd "repo" > /dev/null
    local repo_name=$(git_get_remote_name)
    popd > /dev/null

    IFS=$'\n'
    for linter in ${LINTERS}; do
        local repo_linter="./ci/${repo_name}/linters/${linter}"
        local shared_linter="./ci/shared/linters/${linter}"
        local private_repo_linter="./private-ci/${repo_name}/linters/${linter}"
        if [[ -f "$repo_linter" ]]; then
            echo "Running $repo_linter for-$repo_name with-exit-on-error=true"
            "$repo_linter" "$PWD/repo" true
        elif [[ -f "$private_repo_linter" ]]; then
            echo "Running $private_repo_linter for-$repo_name with-exit-on-error=true"
            "$private_repo_linter" "$PWD/repo" true
        elif [[ -f "$shared_linter" ]]; then
            echo "Running $shared_linter for-$repo_name with-exit-on-error=true"
            "$shared_linter" "$PWD/repo" true
        else
            echo "Unable to find linter ${linter}."
            exit 1
        fi
    done
}

function cleanup() {
    rm -rf $task_tmp_dir
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run $task_tmp_dir "$@"
