#!/bin/bash

set -eEu
set -o pipefail
export RETRY_INTERVAL=10
export MAX_RETRIES=60

function run() {
    local go_version_file="$PWD/$GO_VERSION_FILE"

    if ! [[ -f "$go_version_file" ]]; then
        echo "Missing $GO_VERSION_FILE file"
        exit 1
    fi

    pushd repo > /dev/null

    local release_name=$(bosh_release_name)
    local go_minor_version=$(cat ${go_version_file} | jq -r "if (.releases.\"${release_name}\" == null) then .default else .releases.\"${release_name}\" end")

    for (( i = 0; i <= MAX_RETRIES; i++ ))
    do
        set +e
        digest=$(curl -s -H "Accept: application/json"  https://hub.docker.com/v2/repositories/${IMAGE}/tags | jq "[.results[] | select(.name | startswith(\"go-${go_minor_version}\")) ] | sort_by(.name) | reverse[0] | .digest")
        set -e

        if [ -n "$digest" ]; then
           break
        fi

        echo -n "."
        sleep $RETRY_INTERVAL
    done

    popd > /dev/null

    echo "digest:${digest}" > image_version/version
}

trap 'err_reporter $LINENO' ERR
run "$@"
