#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TASK_NAME="$(basename "$THIS_FILE_DIR")"
export TASK_NAME
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR

function run() {
    local go_version_file="$PWD/$GO_VERSION_FILE"

    if ! [[ -f "$go_version_file" ]]; then
        echo "Missing $GO_VERSION_FILE file"
        exit 1
    fi

    local go_minor_version=$(cat ${go_version_file} | jq -r "if (.releases.\"${RELEASE_NAME}\" == null) then .default else .releases.\"${RELEASE_NAME}\" end")
    echo $go_minor_version > ./ci/go_version.txt
}

trap 'err_reporter $LINENO' ERR
run "$@"
