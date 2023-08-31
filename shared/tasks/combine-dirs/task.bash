#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR

function run() {
  for f in input-*
  do
    ls $f
    cp -r $f/* ./combined-dirs/
  done
}

trap 'err_reporter $LINENO' ERR
run "$@"
