#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/cf-helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/credhub-helpers.bash"
unset THIS_FILE_DIR

function test_api { until bosh env; do echo failed; sleep 1; done; }

function run(){
    local task_tmp_dir="${1:?provide temp dir for task}"
    shift 1

    expand_functions

    bosh_target

    export -f test_api

    timeout 30 bash -c test_api
    if [[ "$(bosh_is_cf_deployed)" == "yes" ]]; then
        cf_target
    fi

    pushd "repo" > /dev/null
    if [[ -f ./bin/prepare-cf-deployment-env.bash ]]; then
        debug "Running ./bin/prepare-cf-deployment-env.bash for repo"
        ./bin/prepare-cf-deployment-env.bash "$@"
    fi
    popd > /dev/null

    touch prepared-env/vars.yml

    if [[ "$(bosh_is_cf_deployed)" == "yes" ]]; then
        cf_create_tcp_domain
        cp "${CF_MANIFEST_FILE}" ./prepared-env/cf.yml

        cat <<EOF > prepared-env/vars.yml
---
CF_ADMIN_PASSWORD: "${CF_ADMIN_PASSWORD}"
CF_DEPLOYMENT: "${CF_DEPLOYMENT}"
CF_ENVIRONMENT_NAME: "${CF_ENVIRONMENT_NAME}"
CF_SYSTEM_DOMAIN: "${CF_SYSTEM_DOMAIN}"
CF_TCP_DOMAIN: "${CF_TCP_DOMAIN}"
CF_MANIFEST_VERSION: "${CF_MANIFEST_VERSION}"
CF_MANIFEST_FILE: "cf.yml"
EOF
    fi
    credhub_save_lb_cert

    if [[ -n "${VARS}" ]]; then
        echo "${VARS}" | yq -P . >> prepared-env/vars.yml
    fi
}

function cleanup() {
    rm -rf $task_tmp_dir
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run $task_tmp_dir "$@"
