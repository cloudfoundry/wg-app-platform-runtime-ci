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

    bosh_target
    local cf_manifest="$(mktemp -p ${task_tmp_dir} -t 'XXXXX-cf.yml')"
    bosh_manifest > "${cf_manifest}"

    pushd repo > /dev/null
    local release_name=$(bosh_release_name)
    popd > /dev/null

    local release_version=$(release="${release_name}" yq '.releases | .[] | select(.name==env(release)) | .version' "${cf_manifest}")
    local stemcell=$(bosh stemcells --json | jq -r --arg os "${OS}" '.Tables[].Rows[] | select(.os | contains($os)) | select(.version | contains("*")) | .os + "/" + .version' | tr -d "*" | sort -V | tail -1)

    local release="${release_name}/${release_version}"

    debug "Running 'bosh export-release -d ${DEPLOYMENT_NAME} ${release} ${stemcell}'"
    bosh export-release -d "${DEPLOYMENT_NAME}" "${release}" "${stemcell}"
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap 'err_reporter $LINENO' ERR
run $task_tmp_dir "$@"
