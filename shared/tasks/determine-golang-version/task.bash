#!/bin/bash

set -eEu
set -o pipefail

function run() {
    local go_version_file="$PWD/$GO_VERSION_FILE"

    pushd repo > /dev/null

    if ! [[ -f "$go_version_file" ]]; then
        echo "Missing $GO_VERSION_FILE file"
        exit 1
    fi

    local go_minor_version=$(cat ${go_version_file} | jq -r "if (.releases.\"${release_name}\" == null) then .default else .releases.\"${release_name}\" end")
    cat go_minor_version > ci/go_version.txt
}

trap 'err_reporter $LINENO' ERR
run "$@"
