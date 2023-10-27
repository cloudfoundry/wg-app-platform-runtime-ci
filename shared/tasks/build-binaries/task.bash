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
    git_configure_safe_directory
    expand_functions

    export GOFLAGS="-buildvcs=false"

    local target="$PWD/built-binaries"

    debug "building binaries for ${MAPPING}"

    for entry in ${MAPPING}
    do
        local function_name=$(echo $entry | cut -d '=' -f1)
        local binary_path=$(echo $entry | cut -d '=' -f2)
        debug "Executing: $function_name $binary_path $target"
        $function_name "repo/$binary_path" "$target"
    done
}

trap 'err_reporter $LINENO' ERR
run "$@"
