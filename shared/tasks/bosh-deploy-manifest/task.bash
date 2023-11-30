#!/bin/bash

set -eEu
set -o pipefail


THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"
unset THIS_FILE_DIR

function run(){
    local task_tmp_dir="${1:?provide temp dir for task}"
    shift 1

    local cf_manifest="$(mktemp -p ${task_tmp_dir} -t 'XXXXX-cf.yml')"
    bosh_target
    bosh_manifest > "${cf_manifest}"
    local default_envs_file="$(mktemp -p ${task_tmp_dir} -t 'XXXXX-env.bash')"
    bosh_extract_manifest_defaults_from_cf "${cf_manifest}" > "${default_envs_file}"
    debug "Extracted defaults vars from CF: $(cat ${default_envs_file})"

    local env_file="$(mktemp -p ${task_tmp_dir} -t 'XXXXX-env.bash')"
    expand_envs "${env_file}"
    . "${env_file}"
    debug "Extracted vars from ENV variable: $(cat ${env_file})"

    local arguments=$(bosh_extract_vars_from_env_files ${default_envs_file} ${env_file})
    for op in ${OPS_FILES:-}
    do
        arguments="${arguments} -o ${op}"
    done
    debug "bosh arguments for deploy: ${arguments}"

    eval "bosh -d ${DEPLOYMENT_NAME} deploy -n ${MANIFEST} --var=DEPLOYMENT_NAME=${DEPLOYMENT_NAME}${arguments}"
}

function cleanup() {
    rm -rf $task_tmp_dir
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run $task_tmp_dir "$@"
