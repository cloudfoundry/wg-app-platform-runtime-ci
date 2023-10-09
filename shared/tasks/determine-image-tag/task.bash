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

function go_version_file_content() {
    local file="$PWD/$GO_VERSION_FILE"

    if ! [[ -f "$file" ]]; then
        echo "Missing $file file"
        exit 1
    fi
    cat $file
}

function for_repo() {
    debug "Running determined-image-tag for_repo with args $*"
    local target_dir="${1:?Provide a target dir}"

    git_configure_safe_directory

    local repo_name
    pushd repo > /dev/null
    repo_name=$(git_get_remote_name)
    popd > /dev/null

    local go_minor_version
    go_minor_version=$(go_version_file_content | jq -r "if (.repositories.\"${repo_name}\" == null) then .default else .plugins.\"${repo_name}\" end")

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

    echo "${tag}" > "${target_dir}/tag"
    echo "Found image with tag: ${tag}"
}

function for_image() {
    debug "Running determined-image-tag for_image with args $*"
    local target_dir="${1:?Provide a target dir}"

    local go_minor_version tag
    go_minor_version=$(go_version_file_content | jq -r "if (.images.\"${IMAGE}\" == null) then .default else .images.\"${IMAGE}\" end")

    tag=$(curl -s https://go.dev/dl/?mode=json | jq -r ".[].version | select(. | startswith(\"go${go_minor_version}\"))")
    tag=${tag#go}

    echo "go-${tag}" > "${target_dir}/tag"
    echo { \"go_version\": \"${tag}\" } > "${target_dir}/build-args"

    echo "Build image with tag: ${tag}"
}

function run() {
    if [[ -d "$PWD/repo" ]]; then
        for_repo "$PWD/determined-tag"
    else
        for_image "$PWD/determined-tag"
    fi
}

trap 'err_reporter $LINENO' ERR
run "$@"
