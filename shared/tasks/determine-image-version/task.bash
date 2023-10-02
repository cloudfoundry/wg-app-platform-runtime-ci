#!/bin/bash

set -eEu
set -o pipefail

function run() {
    local go_version_file="$PWD/$GO_VERSION_FILE"

    if ! [[ -f "$go_version_file" ]]; then
        echo "Missing $GO_VERSION_FILE file"
        exit 1
    fi

    pushd repo > /dev/null

    local release_name=$(bosh_release_name)
    local go_minor_version=$(cat ${go_version_file} | jq -r "if (.releases.\"${release_name}\" == null) then .default else .releases.\"${release_name}\" end")

    digest=$(curl -s -H "Accept: application/json"  https://hub.docker.com/v2/repositories/${IMAGE}/tags | jq "[.results[] | select(.name | startswith(\"go-${go_minor_version}\")) ] | sort_by(.name) | reverse[0] | .digest")

    popd > /dev/null

    echo "digest:${digest}" > image_version/version
}

trap 'err_reporter $LINENO' ERR
run "$@"
