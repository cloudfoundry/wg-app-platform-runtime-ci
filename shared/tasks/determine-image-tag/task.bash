#!/bin/bash

set -eEu
set -o pipefail

export RETRY_INTERVAL=10
export MAX_RETRIES=60

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TASK_NAME="$(basename "$THIS_FILE_DIR")"
export TASK_NAME
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/git-helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"
unset THIS_FILE_DIR

function run() {
    local go_version_file="$PWD/$GO_VERSION_FILE"

    if ! [[ -f "$go_version_file" ]]; then
        echo "Missing $GO_VERSION_FILE file"
        exit 1
    fi

    local go_minor_version
    if [ -n "$PLUGIN" ]; then
        go_minor_version=$(cat ${go_version_file} | jq -r "if (.plugins.\"${PLUGIN}\" == null) then .default else .plugins.\"${PLUGIN}\" end")
    else
        pushd repo > /dev/null

        local release_name=$(bosh_release_name)
        popd > /dev/null

        go_minor_version=$(cat ${go_version_file} | jq -r "if (.releases.\"${release_name}\" == null) then .default else .releases.\"${release_name}\" end")
    fi

    echo "Getting latest tag that starts with go-${go_minor_version} for image ${IMAGE}"

    local tag
    for (( i = 0; i <= MAX_RETRIES; i++ ))
    do
        set +e
        image_info=$(curl -s -H "Accept: application/json"  https://hub.docker.com/v2/repositories/${IMAGE}/tags | jq "[.results[] | select(.name | startswith(\"go-${go_minor_version}\")) ] | sort_by(.name) | reverse[0]" 2>/dev/null)
        set -e

        if [ -n "$image_info" ]; then
            tag=$(echo $image_info | jq -r .name)
            break
        fi

        echo -n "."
        sleep $RETRY_INTERVAL
    done

    echo "${tag}" > image_tag/tag

    echo "Found image with tag: ${tag}"
}

trap 'err_reporter $LINENO' ERR
run "$@"