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

    if [[ "$bosh_blob_path" =~ ^build-deps/ninja- ]]; then
        echo "Bumping ninja blob"
        pushd "${blob}" > /dev/null
        local version
        version=$(cat tag)
        local tgz_name="ninja-${version}.tar.gz"
        mv "source.tar.gz" "${tgz_name}"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local old_blob_name
        old_blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name
        dir_name="$(dirname "${bosh_blob_path}")"
        bosh remove-blob "${dir_name}/${old_blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" =~ ^build-deps/meson- ]]; then
        echo "Bumping meson blob"
        pushd "${blob}" > /dev/null
        local version
        version=$(cat tag)
        local tgz_name="meson-${version}.tar.gz"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local old_blob_name
        old_blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name
        dir_name="$(dirname "${bosh_blob_path}")"
        bosh remove-blob "${dir_name}/${old_blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" =~ ^fuse/fuse- ]]; then
        echo "Bumping libfuse blob"
        pushd "${blob}" > /dev/null
        local version
        version=$(cat version)
        local tgz_name="fuse-${version}.tar.gz"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local old_blob_name
        old_blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name
        dir_name="$(dirname "${bosh_blob_path}")"
        bosh remove-blob "${dir_name}/${old_blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    fi
    popd > /dev/null
}

run "$@"
