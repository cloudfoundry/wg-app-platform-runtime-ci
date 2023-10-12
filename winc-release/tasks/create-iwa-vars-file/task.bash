#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR

one_line_iwa_creds=$(echo ${IWA_CREDENTIAL_SPEC}| jq -c .)
function run(){
    local task_tmp_dir="${1:?provide temp dir for task}"
    shift 1

    cat <<EOF > created-iwa-vars-file/"${FILENAME}"
iwa_dc_ips: "${IWA_DC_IPS}"
iwa_plugin_input: "${IWA_PLUGIN_INPUT}"
iwa_credential_spec: ${one_line_iwa_creds}
EOF
}

function cleanup() {
    rm -rf $task_tmp_dir
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run $task_tmp_dir "$@"
