#!/bin/bash

set -eux
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

    pushd "$repo_path" > /dev/null

    if [[ "$bosh_blob_path" == 'envoy-nginx/envoy-nginx-*.zip' ]]; then
        echo "Bumping nginx blob"
        pushd "${blob}" > /dev/null
        local version=$(git_get_latest_tag | cut -d'-' -f2)
        popd > /dev/null

        local zip_name="envoy-nginx-${version}.zip"
        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$zip_name") ]]; then
            echo "$zip_name already exists, skippping"
            return
        fi

        curl --silent --fail --output nginx.zip "https://nginx.org/download/nginx-${version}.zip"
        unzip -j nginx.zip nginx-*/nginx.exe
        zip "${zip_name}" nginx.exe

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${zip_name}" "${dir_name}/${zip_name}" 
        rm -rf "${zip_name}" nginx.zip nginx.exe
    else
        echo "can't find ${bosh_blob_path}"
        exit 1
    fi
    popd > /dev/null
}

run "$@"
