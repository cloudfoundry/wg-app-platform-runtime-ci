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
    BOSH_INSTALL_TARGET="${target}" bash packages/proxy/packaging
    rm -rf ./proxy
    popd || exit

    cat > "${target}/run.bash" << EOF
export PROXY_BINARY="\$PWD/${built_dir}/proxy/envoy"
EOF
}
