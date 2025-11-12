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

    curl -kL -o "${task_tmp_dir}/fly" "${FLY_URL}/api/v1/cli?arch=amd64&platform=linux"
    FLY_BIN="${task_tmp_dir/fly}"
    chmod 755  "${FLY_BIN}"

    "${FLY_BIN}" -t ci login -c "${FLY_URL}" -u "${FLY_USER}" -p "${FLY_PASSWORD}"
    for worker in $("${FLY_BIN}" -t ci workers | grep -E "${FLY_WORKER_REGEX}" | cut -d " " -f1); do
        "${FLY_BIN}" -t ci prune-worker -w "${worker}"
    done
}

function cleanup() {
    rm -rf $task_tmp_dir
}

if [[ -z "${FLY_WORKER_REGEX}" || "${FLY_WORKER_REGEX}" =~ ^[[:space:]]*$ ]]; then
  echo "Cowardly refusing to prune any workers. Specify FLY_WORKER_REGEX." >&2
  exit 1
fi

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run $task_tmp_dir "$@"
