#!/bin/bash

set -eu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../shared/helpers/git-helpers.bash"
unset THIS_FILE_DIR

function run() {
    local repo_path=${1:?Provide a path to the repository}
    local bosh_blob_path=${2:?Provide a regex path for bosh-blob}
    local blob=${3:?Provide a path to new blob}

    if [[ "$bosh_blob_path" == 'envoy-nginx/envoy-nginx-*.zip' ]]; then
        set +x
        echo "Bumping nginx blob"
        pushd "${blob}" > /dev/null
        local version=$(git_get_latest_tag | cut -d'-' -f2)
        popd > /dev/null

        curl --silent --fail --output nginx.zip "https://nginx.org/download/nginx-${version}.zip"
        unzip -j nginx.zip nginx-*/nginx.exe
        local zip_name="envoy-nginx-${version}.zip"
        zip "${zip_name}" nginx.exe

        local full_blob_path="$(ls blobs/${bosh_blob_path})"
        bosh remove-blob "${full_blob_path}"
        bosh add-blob "${zip_name}" "$(dirname "${bosh_blob_path}")/${zip_name}" 
        rm -rf "${zip_name}" nginx.zip nginx.exe
    fi
}

run "$@"
