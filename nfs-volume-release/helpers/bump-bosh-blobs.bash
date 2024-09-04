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

    if [[ "$bosh_blob_path" == 'autoconf/autoconf-*.tar.gz' ]]; then
        echo "Bumping autoconf blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d '[a-z]')
        local tgz_name="autoconf-${version}.tar.gz"
        wget "https://ftp.gnu.org/gnu/autoconf/autoconf-${version}.tar.gz" -O "${tgz_name}"
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
        wget "https://ftp.gnu.org/gnu/automake/automake-${version}.tar.gz" -O "${tgz_name}"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'cifs-utils/cifs-utils-*.tar.bz2' ]]; then
        echo "Bumping cifs-utils blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d 'cifs-utils-')
        local tgz_name="cifs-utils-${version}.tar.bz2"
        wget "https://download.samba.org/pub/linux-cifs/cifs-utils/cifs-utils-${version}.tar.bz2" -O "${tgz_name}"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'keyutils/keyutils-*.tar.gz' ]]; then
        echo "Bumping keyutils- blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d 'v')
        local tgz_name="keyutils-${version}.tar.gz"
        wget "https://git.kernel.org/pub/scm/linux/kernel/git/dhowells/keyutils.git/snapshot/keyutils-${version}.tar.gz" -O "${tgz_name}"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'libtool/libtool-*.tar.gz' ]]; then
        echo "Bumping libtool blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d '[a-z]')
        local tgz_name="libtool-${version}.tar.gz"
        wget  -O "${tgz_name}" "https://ftp.wayne.edu/gnu/libtool/libtool-${version}.tar.gz"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'pkg-config/pkg-config-*.tar.gz' ]]; then
        echo "Bumping pkg-config blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d '[a-z]-')
        local tgz_name="pkg-config-${version}.tar.gz"
        wget  -O "${tgz_name}" "https://pkgconfig.freedesktop.org/releases/pkg-config-${version}.tar.gz"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'talloc/talloc-*.tar.gz' ]]; then
        echo "Bumping talloc blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d '[a-z]-')
        local tgz_name="talloc-${version}.tar.gz"
        wget  -O "${tgz_name}" "https://download.samba.org/pub/talloc/talloc-${version}.tar.gz"
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
}

run "$@"
