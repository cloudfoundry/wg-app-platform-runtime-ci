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
    local cloud_config="$(mktemp -p ${task_tmp_dir} -t 'XXXXX-cc.yml')"

    pushd $DIR > /dev/null
    bosh_target

    local default_envs_file="$(mktemp -p ${task_tmp_dir} -t 'XXXXX-env.bash')"
    if [[ "$(bosh_is_cf_deployed)" == "yes" ]]; then
        bosh_manifest > "${cf_manifest}"
        bosh_cloud_config > "${cloud_config}"
        bosh_extract_manifest_defaults_from_cf "${cf_manifest}" "${cloud_config}" > "${default_envs_file}"
        debug "Extracted defaults vars from CF: $(cat ${default_envs_file})"
    fi
    popd > /dev/null

    local env_file="$(mktemp -p ${task_tmp_dir} -t 'XXXXX-env.bash')"
    expand_envs "${env_file}"
    . "${env_file}"
    debug "Extracted vars from ENV variable: $(cat ${env_file})"

    eval "${EVAL_CMD:-}"

    local arguments=$(bosh_extract_vars_from_env_files ${default_envs_file} ${env_file})
    for op in ${OPS_FILES:-}
    do
        if [[ ! -f "${op}" ]]; then
            if [[ ! -f "ops-files/${op}" ]]; then
                echo "Can't find ops-file ${op}"
            else
                op="ops-files/${op}"
            fi
        fi
        arguments="${arguments} -o ${op}"
    done

    for vs in ${VARS_FILES:-}
    do
        if [[ ! -f "${vs}" ]]; then
            if [[ ! -f "ops-files/${vs}" ]]; then
                echo "Can't find vars-file ${vs}"
            else
                vs="ops-files/${vs}"
            fi
        fi
        arguments="${arguments} -l ${vs}"
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
