#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR

: "${CONTENT:?Need to set CONTENT}"

function run(){
  local name
  if [[ "${NAME:-undefined}" == "undefined" ]]; then
    name="$(openssl rand -hex 12)"
  else
    name=${NAME}
  fi
  cat > "written-file/${name}" <<EOF
${CONTENT}
EOF
}

trap 'err_reporter $LINENO' ERR
run "$@"
