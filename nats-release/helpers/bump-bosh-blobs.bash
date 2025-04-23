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

    if [[ "$bosh_blob_path" == 'nats-server-gh-release/nats-server-*-linux-amd64.tar.gz' ]]; then
        echo "Bumping nats-server blob"
        pushd "${blob}" > /dev/null
        local version=$(cat version)
        local tgz_name="nats-server-v${version}-linux-amd64.tar.gz"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    else
        echo "$0 doesn't understand how to update ${bosh_blob_path}"
        exit 1
    fi
    popd > /dev/null
}

run "$@"
