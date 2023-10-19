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
    expand_functions

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


    expand_verifications

    if [[ "${DB:-missing}" != "missing" ]]; then
        configure_db "${DB}"
    fi

    pushd "repo/$DIR"  > /dev/null
    if [[ -f ./bin/test.bash ]]; then
        debug "Running ./bin/test.bash for repo/$DIR"
        ./bin/test.bash $(expand_flags) "$@"
    else
        debug "Missing ./bin/test.bash for repo/$DIR. Running ginkgo by default"
        eval "go run github.com/onsi/ginkgo/v2/ginkgo $(expand_flags) $@"
    fi
    popd  > /dev/null
}

function cleanup() {
    rm -rf $task_tmp_dir
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run $task_tmp_dir "$@"
