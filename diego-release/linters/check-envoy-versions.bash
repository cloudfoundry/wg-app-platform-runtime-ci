#!/bin/bash

set -eu
set -o pipefail

function run() {
    local repo_path=${1:?Provide a path to the repository}
    local exit_on_error=${2:-"false"}

    pushd "${repo_path}" > /dev/null

    bosh sync-blobs

    cd blobs/proxy
    tar -xf envoy*.tgz

    local filename_version=$(ls -1 envoy*.tgz | xargs basename | sed 's/envoy-\(.*\).tgz/\1/g')
    local actual_version=$(./envoy --version | grep -vE '^$' | awk '{print $3}' | cut -d/ -f1,2 | tr / -)

    if [ "x$filename_version" != "x$actual_version" ]; then
        echo "Expected $filename_version in $(ls -1 diego-release/blobs/proxy/envoy*.tgz) to match $actual_version"
        if [[ "$exit_on_error" == "true" ]]; then
            exit 1
        fi
    fi
    popd > /dev/null
}

run "$@"
