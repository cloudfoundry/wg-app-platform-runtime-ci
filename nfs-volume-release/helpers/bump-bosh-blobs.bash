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

    if [[ "$bosh_blob_path" == 'berkeleydb/db-*.tar.gz' ]]; then
        echo "Bumping berkeleydb blob"
        pushd "${blob}" > /dev/null
        local version=$(cat version | tr -d 'v')
        local tgz_name="db-${version}.tar.gz"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'nfs-debs/libevent-*-stable.tar.gz' ]]; then
        echo "Bumping libevent blob"
        pushd "${blob}" > /dev/null
        local version=$(cat version | sed  's/release\-//g')
        local tgz_name="libevent-${version}.tar.gz"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'nfs-debs/libtirpc-*.tar.gz' ]]; then
        echo "Bumping libtirpc blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | sed 's/libtirpc\-//g' | sed 's/-/./g')
        local tgz_name="libtirpc-${version}.tar.gz"
        tar czvf "${tgz_name}" ./*
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'nfs-debs/nfs-utils-*.tar.gz' ]]; then
        echo "Bumping nfs-utils blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | cut -d'/' -f3)
        local tgz_name="nfs-utils-${version}.tar.gz"
        tar czvf "${tgz_name}" ./*
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'nfs-debs/rpcbind-*.tar.gz' ]]; then
        echo "Bumping rpcbind blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | cut -d'/' -f3)
        local tgz_name="rpcbind-${version}.tar.gz"
        tar czvf "${tgz_name}" ./*
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'nfs-debs/rpcsvc-proto-*.tar.xz' ]]; then
        echo "Bumping rpcsvc-proto blob"
        pushd "${blob}" > /dev/null
        local version=$(cat tag | tr -d 'v')
        local tgz_name="rpcsvc-proto-${version}.tar.xz"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'nfs-debs/sqlite-*.tar.gz' ]]; then
        echo "Bumping sqlite blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 --match version* | sed 's/version\-//g')
        local tgz_name="sqlite-${version}.tar.gz"
        tar czvf "${tgz_name}" ./*
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'nfs-debs/util-linux-*.tar.gz' ]]; then
        echo "Bumping util-linux blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d 'v')
        local tgz_name="util-linux-${version}.tar.gz"
        tar czvf "${tgz_name}" ./*
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'openldap/openldap-*.tgz' ]]; then
        echo "Bumping openldap blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | sed 's/OPENLDAP_REL_ENG_//g' | sed 's/_/./g')
        local tgz_name="openldap-${version}.tar.gz"
        wget  -O "${tgz_name}" "https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-${version}.tgz"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'test-dependencies/openssl-*.tar.gz' ]]; then
        echo "Bumping openssl blob"
        pushd "${blob}" > /dev/null
        local version=$(cat version)
        local tgz_name="${version}.tar.gz"
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
        echo "can't find ${bosh_blob_path}"
        exit 1
    fi
    popd > /dev/null
}

run "$@"
