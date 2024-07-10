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
    bosh -d "$DEPLOYMENT_NAME" manifest > "${cf_manifest}"

    pushd repo > /dev/null
    local release_name=$(bosh_release_name)
    popd > /dev/null

    local release_version=$(release="${release_name}" yq '.releases | .[] | select(.name==env(release)) | .version' "${cf_manifest}")
    if [ -z "${release_version}" ] || [ "$release_version" == "latest" ]; then
        release_version=$(bosh releases --json | release="${release_name}" jq -r '.Tables[0].Rows[] | select(.name==env.release) | .version' | grep '\*' | cut -d'*' -f1)
    fi

    local stemcell=$(bosh stemcells --json | jq -r --arg os "${OS}" '.Tables[].Rows[] | select(.os | contains($os)) | select(.version | contains("*")) | .os + "/" + .version' | tr -d "*" | sort -V | tail -1)

    local release="${release_name}/${release_version}"

    debug "Running 'bosh export-release -d ${DEPLOYMENT_NAME} ${release} ${stemcell}'"
    bosh export-release -d "${DEPLOYMENT_NAME}" "${release}" "${stemcell}"
}

function cleanup() {
    rm -rf "${task_tmp_dir}"
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run $task_tmp_dir "$@"
