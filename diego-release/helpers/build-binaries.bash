#!/bin/bash

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$THIS_FILE_DIR/../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR

function build_nats_server(){
    local source="${1?Provide source dir}"
    local target="${2?Provide target dir}"

    verify_go

    local built_dir=$(basename "${target}")
    target="$target/nats-server"
    mkdir -p "${target}"

    pushd "$source" || exit
    go build -o "${target}/run" .
    popd || exit

    cat > "${target}/run.bash" << EOF
export NATS_SERVER_BINARY="\$PWD/${built_dir}/nats-server/run"
EOF
}

function build_proxy(){
    local source="${1?Provide source dir}"
    local target="${2?Provide target dir}"

    local built_dir=$(basename "${target}")
    target="$target/proxy"
    mkdir -p "${target}"

    pushd "$source" || exit
    bosh sync-blobs
    ln -s ./blobs/proxy ./proxy
    chmod +x packages/proxy/packaging
    BOSH_INSTALL_TARGET="${target}" packages/proxy/packaging
    popd || exit

    cat > "${target}/run.bash" << EOF
export PROXY_BINARY="\$PWD/${built_dir}/proxy/envoy"
EOF
}
