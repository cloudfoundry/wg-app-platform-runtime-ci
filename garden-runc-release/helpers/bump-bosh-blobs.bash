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
        local version=$(git describe --tags --abbrev=0 | tr -d 'v')
        local tgz_name="apparmor-${version}.tar.gz"
        wget "https://gitlab.com/apparmor/apparmor/-/archive/v${version}/apparmor-v${version}.tar.gz" -O "${tgz_name}"
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
    elif [[ "$bosh_blob_path" == 'gperf/gperf-*.tar.gz' ]]; then
        echo "Bumping gperf blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d '[a-z]')
        local tgz_name="gperf-${version}.tar.gz"
        wget  -O "${tgz_name}" "http://ftp.gnu.org/pub/gnu/gperf/gperf-${version}.tar.gz"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'iptables/iptables-*.tar.bz2' ]]; then
        echo "Bumping iptables blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d '[a-z]')
        local tgz_name="iptables-${version}.tar.xz"
        wget  -O "${tgz_name}" "https://netfilter.org/projects/iptables/files/iptables-${version}.tar.xz"
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
        wget  -O "${tgz_name}" "https://www.netfilter.org/projects/libmnl/files/libmnl-${version}.tar.bz2"
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
        wget  -O "${tgz_name}" "https://www.netfilter.org/projects/libnftnl/files/libnftnl-${version}.tar.xz"
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
    elif [[ "$bosh_blob_path" == 'musl/musl-*.tar.gz' ]]; then
        echo "Bumping musl blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d '[a-z]')
        local tgz_name="libtool-${version}.tar.gz"
        wget  -O "${tgz_name}" "https://musl.libc.org/releases/musl-${version}.tar.gz"
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
    elif [[ "$bosh_blob_path" == 'tar/tar-*.tar.xz' ]]; then
        echo "Bumping tar blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d '[a-z]-')
        local tgz_name="tar-${version}.tar.xz"
        wget  -O "${tgz_name}" "https://ftp.wayne.edu/gnu/tar/tar-${version}.tar.xz"
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
        wget  -O "${tgz_name}" "https://github.com/krallin/tini/archive/refs/tags/v${version}.tar.gz"
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
        wget  -O "${tgz_name}" "https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v${major_minor_version}/util-linux-${version}.tar.gz"
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
        wget  -O "${tgz_name}" "https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v${major_minor_version}/util-linux-${version}.tar.gz"
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'xfs-progs/xfsprogs-*.tar.gz' ]]; then
        echo "Bumping xfs-progs blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d '[a-z]-')
        local tgz_name="xfs-progs-${version}.tar.gz"
        wget  -O "${tgz_name}" "https://mirrors.edge.kernel.org/pub/linux/utils/fs/xfs/xfsprogs/xfsprogs-${version}.tar.gz"
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
    else
        echo "can't find ${bosh_blob_path}"
        exit 1
    fi
}

run "$@"
