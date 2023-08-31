#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR

: "${GLOB:?Need to set GLOB}"
function run(){
  for f in ${GLOB}
  do
    ls $f
    cp $f ./combined-files/"${PREFIX}$(basename $f)"
  done
}

trap 'err_reporter $LINENO' ERR
run "$@"
