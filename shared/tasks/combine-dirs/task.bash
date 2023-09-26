#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR

function run() {
  for input in input-*
  do
    if [[ "${GLOB:-empty}" == "empty" ]]; then
      ls $input
      cp -r $input/* ./combined-dirs/
    else
      for glob in ${GLOB}
      do
        cp -r $input/$glob ./combined-dirs/ || true
      done
    fi
  done
}

trap 'err_reporter $LINENO' ERR
run "$@"
