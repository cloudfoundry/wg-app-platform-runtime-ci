#!/bin/bash

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$THIS_FILE_DIR/../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR

function build_tar(){
    local source="${1?Provide source dir}"
    local target="${2?Provide target dir}"

    local built_dir=$(basename "${target}")
    target="$target/tar"
    mkdir -p "${target}"

    pushd "$source" || exit
    bosh sync-blobs
    ln -s ./blobs/tar ./tar
    ln -s ./blobs/musl ./musl
    chmod +x packages/tar/packaging
    BOSH_INSTALL_TARGET="${target}" packages/tar/packaging
    mv "${target}/tar" "${target}/run"
    popd || exit

    cat > "${target}/run.bash" << EOF
export TAR_BINARY="\$PWD/${built_dir}/tar/run"
EOF
}
