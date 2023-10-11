#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR

: "${COPY_ACTIONS:?Need to set COPY_ACTIONS}"
function run(){
  for copy_action in ${COPY_ACTIONS}
  do
    debug "Copying: ${copy_action}"
    eval "cp -r ${copy_action}"
  done
}

trap 'err_reporter $LINENO' ERR
run "$@"
