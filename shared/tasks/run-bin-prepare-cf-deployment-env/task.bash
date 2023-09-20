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

function run(){
    local task_tmp_dir="${1:?provide temp dir for task}"
    shift 1

    expand_functions

    bosh_target
    cf_target
    cf_create_tcp_domain
    credhub_save_lb_cert

    pushd "repo" > /dev/null
    if [[ -f ./bin/prepare-cf-deployment-env.bash ]]; then
        debug "Running ./bin/prepare-env.bash for repo"
        ./bin/prepare-cf-deployment-env.bash "$@"
    fi
    popd > /dev/null

    cat <<EOF > prepared-env/vars.yml
---
CF_ADMIN_PASSWORD: "${CF_ADMIN_PASSWORD}"
CF_ENVIRONMENT_NAME: "${CF_ENVIRONMENT_NAME}"
CF_SYSTEM_DOMAIN: "${CF_SYSTEM_DOMAIN}"
CF_TCP_DOMAIN: "${CF_TCP_DOMAIN}"
CF_MANIFEST_VERSION: "${CF_MANIFEST_VERSION}"
EOF
}

function cleanup() {
    rm -rf $task_tmp_dir
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run $task_tmp_dir "$@"
