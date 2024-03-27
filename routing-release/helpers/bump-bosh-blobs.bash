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

    if [[ "$bosh_blob_path" == 'jq/jq-*-linux-amd64.tgz' ]]; then
        echo "Bumping jq blob"
        pushd "${blob}" > /dev/null
        local version=$(cat version | tr -d 'jq-')
        local tgz_name="jq-${version}-linux-amd64.tgz"
        mv jq-linux-amd64 jq
        tar czvf "${tgz_name}" jq
        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "$tgz_name already exists, skippping"
            return
        fi

        local blob_name="$(basename blobs/${bosh_blob_path})"
        local dir_name="$(dirname ${bosh_blob_path})"
        bosh remove-blob "${dir_name}/${blob_name}"
        bosh add-blob "${blob}/${tgz_name}" "${dir_name}/${tgz_name}"
    elif [[ "$bosh_blob_path" == 'haproxy/haproxy-*.tar.gz' ]]; then
        echo "Bumping haproxy blob"
        pushd "${blob}" > /dev/null
        local version=$(git describe --tags --abbrev=0 | tr -d '[a-z]-')
        local tgz_name="haproxy-${version}.tar.gz"
        local major_minor_version="$(echo ${version} | cut -d'.' -f1,2)"
        wget -O "${tgz_name}" "https://www.haproxy.org/download/${major_minor_version}/src/haproxy-${version}.tar.gz"

        popd > /dev/null

        if [[ -f $(find ./blobs  -type f -regextype posix-extended -regex ".*$tgz_name") ]]; then
            echo "${tgz_name} already exists, skippping"
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
