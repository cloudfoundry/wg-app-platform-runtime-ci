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

    if [[ "$bosh_blob_path" == 'apparmor/apparmor-*.tar.gz' ]]; then
        echo "Bumping apparmor blob"
        pushd "${blob}" > /dev/null
        local version=$(cat version | tr -d 'v')
        local tgz_name="apparmor-${version}.tar.gz"
        wget "https://gitlab.com/apparmor/apparmor/-/archive/v${version}/apparmor-v${version}.tar.gz" -o "${tgz_name}"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'autoconf/autoconf-*.tar.gz' ]]; then
        echo "Bumping autoconf blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d '[a-z]')
        local tgz_name="autoconf-${version}.tar.gz"
        wget "https://ftp.gnu.org/gnu/autoconf/autoconf-${version}.tar.gz" -o "${tgz_name}"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'automake/automake-*.tar.gz' ]]; then
        echo "Bumping automake blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d 'v')
        local tgz_name="automake-${version}.tar.gz"
        wget "https://ftp.gnu.org/gnu/automake/automake-${version}.tar.gz" -o "${tgz_name}"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'busybox/busybox-*.tar.gz' ]]; then
        echo "Bumping busybox blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d 'v')
        local blob_version=$(echo ${version} | sed s/_/./g)
        local tgz_name="busybox-${blob_version}.tar.gz"
        wget "https://git.busybox.net/busybox/snapshot/busybox-${version}.tar.bz2"
        bunzip2 -c -d "busybox-${version}.tar.bz2" | gzip -v9 > ${tgz_name}
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
