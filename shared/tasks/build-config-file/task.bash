#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/cf-helpers.bash"
unset THIS_FILE_DIR

function run(){
    local task_tmp_dir="${1:?provide temp dir for task}"
    shift 1

    local env_file="$(mktemp -p ${task_tmp_dir} -t 'XXXXX-env.bash')"
    expand_envs "${env_file}"
    . "${env_file}"

    eval "${EVAL_YAML_CONFIG}" | yq -r . > "./built-config-file/config.yml"
    eval "${EVAL_YAML_CONFIG}" | yq -r . -o "json" | jq -r . > "./built-config-file/config.json"
}

function cleanup() {
    rm -rf $task_tmp_dir
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run $task_tmp_dir "$@"
