#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR

: "${YTT_ARGS:?Need to set YTT_ARGS}"
function run(){
  ytt ${YTT_ARGS} > ytt-output/merged.yml
}

trap 'err_reporter $LINENO' ERR
run "$@"
