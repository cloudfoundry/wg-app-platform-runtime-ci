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

    local tmpDir=$(mktemp -d -p /tmp "build-tar-XXXX")

    rsync -aq "$source/" "$tmpDir"
    pushd "$tmpDir" || exit
    bosh sync-blobs
    ln -s ./blobs/tar ./tar
    ln -s ./blobs/musl ./musl
    echo "Executing tar packaging script"
    BOSH_INSTALL_TARGET="${target}" bash packages/tar/packaging &> /dev/null
    mv "${target}/tar" "${target}/run"
    popd || exit
    rm -rf "$tmpDir"

    cat > "${target}/run.bash" << EOF
export TAR_BINARY="\$PWD/${built_dir}/tar/run"
EOF
}

function build_nstar(){
    local source="${1?Provide source dir}"
    local target="${2?Provide target dir}"

    local built_dir=$(basename "${target}")
    target="$target/nstar"
    mkdir -p "${target}"

    pushd "$source" || exit
    make clean
    if [  "${WITH_MUSL:-no}" == "no" ]; then
      make
    else
      CC="${WITH_MUSL}" make
    fi
    mv nstar "${target}"
    popd || exit

    cat > "${target}/run.bash" << EOF
export NSTAR_BINARY="\$PWD/${built_dir}/nstar/nstar"
EOF
    
}

function build_socket2me(){
    local source="${1?Provide source dir}"
    local target="${2?Provide target dir}"

    local built_dir=$(basename "${target}")
    target="$target/socket2me"
    mkdir -p "${target}"

    pushd "$source" || exit
    go build -o "${target}/run" .
    popd || exit

    cat > "${target}/run.bash" << EOF
export SOCKET2ME_BINARY="\$PWD/${built_dir}/socket2me/run"
EOF
    
}

function build_fake_runc_stderr(){
    local source="${1?Provide source dir}"
    local target="${2?Provide target dir}"

    local built_dir=$(basename "${target}")
    target="$target/fake_runc_stderr"
    mkdir -p "${target}"

    pushd "$source" || exit
    go build -o "${target}/run" .
    popd || exit

    cat > "${target}/run.bash" << EOF
export FAKE_RUNC_STDERR_BINARY="\$PWD/${built_dir}/fake_runc_stderr/run"
EOF
    
}

function build_runc() {
    local source="${1?Provide source dir}"
    local target="${2?Provide target dir}"

    local built_dir=$(basename "${target}")
    target="$target/runc"
    mkdir -p "${target}"

    pushd "$source" || exit
    make BUILDTAGS='seccomp apparmor' static
    mv runc "${target}"
    popd || exit

    cat > "${target}/run.bash" << EOF
export RUNC_BINARY="\$PWD/${built_dir}/runc/runc"
EOF
}

function build_grootfs() {
    local source="${1?Provide source dir}"
    local target="${2?Provide target dir}"

    local built_dir=$(basename "${target}")
    target="$target/grootfs"
    mkdir -p "${target}"

    pushd "$source" || exit
    make clean
    if [  "${WITH_MUSL:-no}" == "no" ]; then
      make
    else
      CC="${WITH_MUSL}" STATIC_BINARY=true make
    fi
    make prefix="${target}" install
    popd || exit

    cat > "${target}/run.bash" << EOF
export GROOTFS_BINARY="\$PWD/${built_dir}/grootfs/grootfs"
export GROOTFS_TARDIS_BINARY="\$PWD/${built_dir}/grootfs/tardis"
EOF
}

function build_init() {
    local source="${1?Provide source dir}"
    local target="${2?Provide target dir}"

    local built_dir=$(basename "${target}")
    target="$target/init"
    mkdir -p "${target}"

    pushd "$source" || exit
    if [  "${WITH_MUSL:-no}" == "no" ]; then
      gcc -static -o init init.c ignore_sigchild.c
    else
      CC="${WITH_MUSL}" gcc -static -o init init.c ignore_sigchild.c
    fi
    mv init "${target}/run"
    popd || exit

    cat > "${target}/run.bash" << EOF
export INIT_BINARY="\$PWD/${built_dir}/init/run"
EOF
}

function build_dadoo() {
    local source="${1?Provide source dir}"
    local target="${2?Provide target dir}"

    local built_dir=$(basename "${target}")
    target="$target/dadoo"
    mkdir -p "${target}"

    verify_go

    pushd "$source" || exit
    go build -o "${target}/run" .
    popd || exit

    cat > "${target}/run.bash" << EOF
export DADOO_BINARY="\$PWD/${built_dir}/dadoo/run"
EOF
}

function build_idmapper() {
    local source="${1?Provide source dir}"
    local target="${2?Provide target dir}"

    local built_dir=$(basename "${target}")
    target="$target/idmapper"
    mkdir -p "${target}"

    verify_go

    pushd "$source" || exit
    go build -o "${target}/newuidmap" ./cmd/newuidmap
    go build -o "${target}/newgidmap" ./cmd/newgidmap
    go build -o "${target}/maximus" ./cmd/maximus
    popd || exit

    cat > "${target}/run.bash" << EOF
export IDMAPPER_NEWUIDMAP_BINARY="\$PWD/${built_dir}/idmapper/newuidmap"
export IDMAPPER_NEWGIDMAP_BINARY="\$PWD/${built_dir}/idmapper/newgidmap"
export IDMAPPER_MAXIMUS_BINARY="\$PWD/${built_dir}/idmapper/maximus"
EOF
}

function build_containerd() {
    local source="${1?Provide source dir}"
    local target="${2?Provide target dir}"

    local built_dir=$(basename "${target}")
    target="$target/containerd"
    mkdir -p "${target}"

    verify_go

    pushd "$source" || exit
    BUILDTAGS=no_btrfs make ./bin/containerd
    BUILDTAGS=no_btrfs make ./bin/containerd-shim
    BUILDTAGS=no_btrfs make ./bin/containerd-shim-runc-v1
    BUILDTAGS=no_btrfs make ./bin/containerd-shim-runc-v2
    BUILDTAGS=no_btrfs make ./bin/ctr
    mv -f bin/* "${target}"
    popd || exit

    cat > "${target}/run.bash" << EOF
export CONTAINERD_BINARY="\$PWD/${built_dir}/containerd/containerd"
export CONTAINERD_SHIM_BINARY="\$PWD/${built_dir}/containerd/containerd-shim"
export CONTAINERD_SHIM_RUNC_V1_BINARY="\$PWD/${built_dir}/containerd/containerd-shim-runc-v1"
export CONTAINERD_SHIM_RUNC_V2_BINARY="\$PWD/${built_dir}/containerd/containerd-shim-runc-v2"
export CONTAINERD_CTR_BINARY="\$PWD/${built_dir}/containerd/ctr"
EOF
}
