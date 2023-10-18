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
        package_name=$(cd repo && basename packages/golang-*-linux)
        fingerprint="$(cd repo && yq -r .fingerprint < "packages/${package_name}/spec.lock")"
        pkg_version=$(cd package-release && ./scripts/get-package-version.sh "${fingerprint}" "${package_name}")

        go_minor_version="${pkg_version%.*}"
    fi

    token=$(curl -s -H "Content-type: application/json" -X POST --data "{\"username\":\"${DOCKER_REGISTRY_USERNAME}\",\"password\":\"${DOCKER_REGISTRY_PASSWORD}\"}" https://hub.docker.com/v2/users/login | jq -r .token)

    echo "Getting latest tag that starts with go-${go_minor_version} for image ${IMAGE}"

    local tag
    for (( i = 0; i <= MAX_RETRIES; i++ ))
    do
        set +e
        image_info=$(curl -s -H "Accept: application/json"  -H "Authorization: Bearer ${token}" https://hub.docker.com/v2/repositories/${IMAGE}/tags | jq "[.results[] | select(.name | startswith(\"go-${go_minor_version}\")) ] | sort_by(.name) | reverse[0]" 2>/dev/null)
        set -e

        if [ -n "$image_info" ]; then
            tag=$(echo $image_info | jq -r .name)
            break
        fi

        echo -n "."
        sleep $RETRY_INTERVAL
    done

    echo "${tag}" > determined-image-tag/tag

    echo "Found image with tag: ${tag}"
}

trap 'err_reporter $LINENO' ERR
run "$@"
