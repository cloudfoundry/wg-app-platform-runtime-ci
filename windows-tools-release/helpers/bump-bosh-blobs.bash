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

    if [[ "$bosh_blob_path" == 'yq/yq-*-windows-amd64.exe' ]]; then
        echo "Bumping yq blob"
        pushd "${blob}" > /dev/null
        local version=$(cat version)
        local exe_name="yq-${version}-windows-amd64.exe"
        mv yq_windows_amd64.exe "${exe_name}"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$exe_name") ]]; then
            echo "$exe_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${exe_name}" "${dir_name}/${exe_name}"
    elif [[ "$bosh_blob_path" == 'staticcheck/staticcheck-*-windows-amd64.tar.gz' ]]; then
        echo "Bumping staticcheck blob"
        pushd "${blob}" > /dev/null
        local version=$(cat version)
        local tgz_name="staticcheck-${version}-windows-amd64.tar.gz"
        mv staticcheck_windows_amd64.tar.gz  "${tgz_name}"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    fi
}

run "$@"