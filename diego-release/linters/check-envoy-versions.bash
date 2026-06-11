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

    # On aarch64 hosts the envoy blob is x86-64 and cannot be executed for version inspection.
    # Skip the execution-based check; the filename convention is sufficient on ARM dev machines.
    local host_arch
    host_arch=$(uname -m)
    local binary_arch
    binary_arch=$(file -b ./envoy 2>/dev/null | grep -oE 'x86-64|aarch64|ARM aarch64' | head -1 || true)
    if [[ "$host_arch" == "aarch64" && "$binary_arch" == "x86-64" ]]; then
        echo "INFO: Skipping envoy binary version check (x86-64 binary on aarch64 host — cannot execute)"
        popd > /dev/null
        return 0
    fi

    local actual_version=$(./envoy --version | grep -vE '^$' | awk '{print $3}' | cut -d/ -f1,2 | tr / -)

    if [ "x$filename_version" != "x$actual_version" ]; then
        echo "Expected $filename_version in $(ls -1 envoy*.tgz) to match $actual_version"
        if [[ "$exit_on_error" == "true" ]]; then
            exit 1
        fi
    fi
    popd > /dev/null
}

run "$@"
