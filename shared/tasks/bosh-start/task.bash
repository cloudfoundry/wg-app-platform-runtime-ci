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

    eval "${BOSH_CREDS}"
    mkdir -p "$(dirname "${JUMPBOX_PRIVATE_KEY}")"
    echo "${SSH_PRIVATE_KEY}" > "${JUMPBOX_PRIVATE_KEY}"
    chmod 600 "${JUMPBOX_PRIVATE_KEY}"
    wait_for_bosh_lock
    bosh -n -d "${DEPLOYMENT}" start "${INSTANCE_GROUP}"
    sleep 120 # sleep to make sure the vm finishes starting up happily for all things that rely on it
}

function cleanup() {
    rm -rf $task_tmp_dir
}

if [[ -z "${INSTANCE_GROUP}" || "${INSTANCE_GROUP}" =~ ^[[:space:]]*$ ]]; then
  echo "Miserly refusing to stop all jobs. Specify INSTANCE_GROUP." >&2
  exit 1
fi

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run $task_tmp_dir "$@"
