#!/bin/bash

# @AI-Generated
# Generated in whole or in part by Cursor with a mix of different LLM models (Auto select mode)
# Description:
# 2026-04-27: External tarball fetches use retry_http_download_until_success.

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

    if [[ "$bosh_blob_path" == 'autoconf/autoconf-*.tar.gz' ]]; then
        echo "Bumping autoconf blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d '[a-z]')
        local tgz_name="autoconf-${version}.tar.gz"
        retry_http_download_until_success "https://ftp.gnu.org/gnu/autoconf/autoconf-${version}.tar.gz" "${tgz_name}" 900 30 "garden autoconf"
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
        retry_http_download_until_success "https://ftp.gnu.org/gnu/automake/automake-${version}.tar.gz" "${tgz_name}" 900 30 "garden automake"
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

        # The busybox blob must be a rootfs tarball (containing /bin/busybox,
        # /bin/cat, /bin/sh, etc.), not source code. It is used directly as a
        # container rootfs by Garden/Groot without any compilation step.
        # Extracting it from the official Docker Hub busybox image.
        local container_name="busybox-export-$$"
        crane export "busybox:${blob_version}" - | gzip -v9 > "${tgz_name}"
        popd > /dev/null


        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'gperf/gperf-*.tar.gz' ]]; then
        echo "Bumping gperf blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d '[a-z]')
        local tgz_name="gperf-${version}.tar.gz"
        retry_http_download_until_success "http://ftp.gnu.org/pub/gnu/gperf/gperf-${version}.tar.gz" "${tgz_name}" 900 30 "garden gperf"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'iptables/iptables-*.tar.xz' ]]; then
        echo "Bumping iptables blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d '[a-z]')
        local tgz_name="iptables-${version}.tar.xz"
        retry_http_download_until_success "https://netfilter.org/projects/iptables/files/iptables-${version}.tar.xz" "${tgz_name}" 900 30 "garden iptables"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'iptables/libmnl-*.tar.bz2' ]]; then
        echo "Bumping libmnl blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d '[a-z]-')
        local tgz_name="libmnl-${version}.tar.bz2"
        retry_http_download_until_success "https://www.netfilter.org/projects/libmnl/files/libmnl-${version}.tar.bz2" "${tgz_name}" 900 30 "garden libmnl"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'iptables/libnftnl-*.tar.xz' ]]; then
        echo "Bumping libnftnl blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d '[a-z]-')
        local tgz_name="libnftnl-${version}.tar.xz"
        retry_http_download_until_success "https://www.netfilter.org/projects/libnftnl/files/libnftnl-${version}.tar.xz" "${tgz_name}" 900 30 "garden libnftnl"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'libseccomp/libseccomp-*.tar.gz' ]]; then
        echo "Bumping libseccomp blob"
        pushd "${blob}" > /dev/null
        local version=$(cat version)
        local tgz_name="libseccomp-${version}.tar.gz"
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
        local version=$(git describe --tags --abbrev=0 | tr -d '[a-z]/')
        local tgz_name="libtool-${version}.tar.gz"
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
    elif [[ "$bosh_blob_path" == 'musl/musl-*.tar.gz' ]]; then
        echo "Bumping musl blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d '[a-z]')
        local tgz_name="musl-${version}.tar.gz"
        retry_http_download_until_success "https://musl.libc.org/releases/musl-${version}.tar.gz" "${tgz_name}" 900 30 "garden musl"
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
        retry_http_download_until_success "https://pkgconfig.freedesktop.org/releases/pkg-config-${version}.tar.gz" "${tgz_name}" 900 30 "garden pkg-config"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'tar/tar-*.tar.xz' ]]; then
        echo "Bumping tar blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d '[a-z]-')
        local tgz_name="tar-${version}.tar.xz"
        retry_http_download_until_success "https://ftp.wayne.edu/gnu/tar/tar-${version}.tar.xz" "${tgz_name}" 900 30 "garden tar"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'tini/tini-*.tar.gz' ]]; then
        echo "Bumping tini blob"
        pushd "${blob}" > /dev/null
        local version=$(cat version)
        local tgz_name="tini-${version}.tar.gz"
        retry_http_download_until_success "https://github.com/krallin/tini/archive/refs/tags/v${version}.tar.gz" "${tgz_name}" 900 30 "garden tini"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'util-linux/util-linux-*.tar.gz' ]]; then
        echo "Bumping util-linux blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d '[a-z]-')
        local major_minor_version="$(echo ${version} | cut -d'.' -f1,2)"
        local tgz_name="util-linux-${version}.tar.gz"
        retry_http_download_until_success "https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v${major_minor_version}/util-linux-${version}.tar.gz" "${tgz_name}" 900 30 "garden util-linux"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'zlib/zlib-*.tar.gz' ]]; then
        echo "Bumping zlib blob"
        pushd "${blob}" > /dev/null
        local version=$(cat version)
        local tgz_name="zlib-${version}.tar.gz"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == "containerd/containerd-*-linux-amd64.tar.gz" ]]; then
        echo "Bumping containerd blob"
        pushd "${blob}" > /dev/null
        local version=$(cat version)
        local tgz_name="containerd-${version}-linux-amd64.tar.gz"
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
