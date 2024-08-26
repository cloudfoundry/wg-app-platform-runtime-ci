#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR

: "${FILES:?Need to set list of FILES}"
function run(){
  local output="./built-json-files/$OUTPUT_FILE"
  echo '{}' > "${output}"

  for file in ${FILES}
  do
    debug "Applying: ${file}"
    local temp_json="$(mktemp -t 'XXXXX-combine-json-files.json')"
    jq -s '.[0] * .[1]' "${output}" "${file}" > "${temp_json}"
    mv "${temp_json}" "${output}"
  done
}

trap 'err_reporter $LINENO' ERR
run "$@"
