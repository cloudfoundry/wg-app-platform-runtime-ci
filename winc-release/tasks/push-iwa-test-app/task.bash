#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/cf-helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"

unset THIS_FILE_DIR

ORG_NAME="iwa-org"
SPACE_NAME="iwa-space"
function run(){
    local task_tmp_dir="${1:?provide temp dir for task}"
    shift 1

    cf_target
    cf_command "create-org ${ORG_NAME}"
    cf_command "create-space -o ${ORG_NAME} ${SPACE_NAME}"
    cf_command "target -o ${ORG_NAME} -s ${SPACE_NAME}"

cat << EOF > "${task_tmp_dir}/manifest.yml" 
applications:
- name: iwa-test-app
  memory: 1G
  stack: windows
  buildpacks:
    - hwc_buildpack
  routes:
    - route: ${CF_TCP_DOMAIN}:1030
      protocol: tcp
EOF

    pushd repo/src/WindowsAuth > /dev/null
    cf_command "push --manifest ${task_tmp_dir}/manifest.yml" 
}

function cleanup() {
    rm -rf $task_tmp_dir
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run $task_tmp_dir "$@"
