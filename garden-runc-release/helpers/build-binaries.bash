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

function build_pkg_config(){
    local source="${1?Provide source dir}"
    local target="${2?Provide target dir}"

    mkdir -p "${target}"
    local built_dir=$(basename "${target}")
    target="$target/pkg-config"
    mkdir -p "${target}"

    local tmpDir=$(mktemp -d -p /tmp "build-pkg-config-XXXX")

    rsync -aq "$source/" "$tmpDir"
    pushd "$tmpDir" || exit
    bosh sync-blobs
    ln -s ./blobs/pkg-config ./pkg-config
    echo "Executing pkg-config packaging script"
    BOSH_INSTALL_TARGET="${target}" bash packages/pkg-config/packaging &> /dev/null
    popd || exit
    rm -rf "$tmpDir"
}

function build_musl(){
    local source="${1?Provide source dir}"
    local target="${2?Provide target dir}"

    local built_dir=$(basename "${target}")
    target="$target/musl"
    mkdir -p "${target}"

    local tmpDir=$(mktemp -d -p /tmp "build-musl-XXXX")

    rsync -aq "$source/" "$tmpDir"
    pushd "$tmpDir" || exit
    bosh sync-blobs
    local musl_tarball="$(ls ./blobs/musl/musl-*.tar.gz)"
    tar xzf "$musl_tarball" --strip-components=1
    echo "Building musl gcc..."
    ./configure --prefix="$target" &> /dev/null
    make install &> /dev/null

    ln -sf /usr/include/linux "$target/include/"
    ln -sf /usr/include/asm-generic "$target/include/"
    ln -sf /usr/include/asm-generic "$target/include/asm"

    popd || exit
    rm -rf "$tmpDir"

    cat > "${target}/run.bash" << EOF
export MUSL_BINARY="\$PWD/${built_dir}/musl/bin/musl-gcc"
EOF
}

function build_iptables(){
    local source="${1?Provide source dir}"
    local target="${2?Provide target dir}"

    build_pkg_config $source "/var/vcap/packages"

    local built_dir=$(basename "${target}")
    target="$target/iptables"
    mkdir -p "${target}"

    local tmpDir=$(mktemp -d -p /tmp "build-iptables-XXXX")

    rsync -aq "$source/" "$tmpDir"
    pushd "$tmpDir" || exit
    bosh sync-blobs
    ln -s ./blobs/iptables ./iptables
    echo "Executing iptables packaging script"
    STATIC=true BOSH_INSTALL_TARGET="/var/vcap/packages/iptables" bash packages/iptables/packaging &> /dev/null
    cp -aL "/var/vcap/packages/iptables/sbin/iptables" "${target}/iptables"
    cp -aL "/var/vcap/packages/iptables/sbin/iptables-restore" "${target}/iptables-restore"
    popd || exit
    rm -rf "$tmpDir"

    cat > "${target}/run.bash" << EOF
export IPTABLES_BINARY="\$PWD/${built_dir}/iptables/iptables"
export IPTABLES_RESTORE_BINARY="\$PWD/${built_dir}/iptables/iptables-restore"
EOF
}

function build_nstar(){
    local source="${1?Provide source dir}"
    local target="${2?Provide target dir}"

    if [[ "${WITH_MUSL:-no}" != "no" ]]; then
        build_musl "$(echo ${source}|cut -d '/' -f1)" "${target}"
        . "${target}/musl/run.bash"
    fi

    local built_dir=$(basename "${target}")
    target="$target/nstar"
    mkdir -p "${target}"

    pushd "$source" || exit
    make clean
    if [  "${WITH_MUSL:-no}" != "no" ]; then
        CC="${MUSL_BINARY}" make
    else
        make
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

    if [[ "${WITH_MUSL:-no}" != "no" ]]; then
        build_musl "$(echo ${source}|cut -d '/' -f1)" "${target}"
        . "${target}/musl/run.bash"
    fi

    local built_dir=$(basename "${target}")
    target="$target/grootfs"
    mkdir -p "${target}"

    pushd "$source" || exit
    make clean
    if [  "${WITH_MUSL:-no}" != "no" ]; then
        CC="${MUSL_BINARY}" STATIC_BINARY=true make
    else
        make
    fi
    make prefix="${target}" install
    popd || exit

    cat <<EOF > ${target}/grootfs-privileged.yml
---
store: /var/lib/grootfs/store-privileged
tardis_bin: \${GROOTFS_TARDIS_BINARY}
newuidmap_bin: \${IDMAPPER_NEWUIDMAP_BINARY}
newgidmap_bin: \${IDMAPPER_NEWGIDMAP_BINARY}
log_level: error

create:
  with_clean: false
  without_mount: false

init:
  store_size_bytes: 51398832128
EOF

cat <<EOF > ${target}/grootfs.yml
---
store: /var/lib/grootfs/store
tardis_bin: \${GROOTFS_TARDIS_BINARY}
newuidmap_bin: \${IDMAPPER_NEWUIDMAP_BINARY}
newgidmap_bin: \${IDMAPPER_NEWGIDMAP_BINARY}
log_level: error

create:
  with_clean: false
  without_mount: false

init:
  store_size_bytes: 51398832128
EOF

cat > "${target}/run.bash" << EOF
export GROOTFS_BINARY="\$PWD/${built_dir}/grootfs/grootfs"
export GROOTFS_TARDIS_BINARY="\$PWD/${built_dir}/grootfs/tardis"
export GROOTFS_REGULAR_CONFIG="\$PWD/${built_dir}/grootfs/grootfs.yml"
export GROOTFS_PRIVILEGED_CONFIG="\$PWD/${built_dir}/grootfs/grootfs-privileged.yml"
EOF
}

function build_init() {
    local source="${1?Provide source dir}"
    local target="${2?Provide target dir}"

    if [[ "${WITH_MUSL:-no}" != "no" ]]; then
        build_musl "$(echo ${source}|cut -d '/' -f1)" "${target}"
        . "${target}/musl/run.bash"
    fi

    local built_dir=$(basename "${target}")
    target="$target/init"
    mkdir -p "${target}"

    pushd "$source" || exit
    if [  "${WITH_MUSL:-no}" != "no" ]; then
        CC="${MUSL_BINARY}" gcc -static -o init init.c ignore_sigchild.c
    else
        gcc -static -o init init.c ignore_sigchild.c
    fi
    mv init "${target}/init"
    popd || exit

    cat > "${target}/run.bash" << EOF
export INIT_BINARY="\$PWD/${built_dir}/init/init"
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
    go build -o "${target}/dadoo" .
    popd || exit

    cat > "${target}/run.bash" << EOF
export DADOO_BINARY="\$PWD/${built_dir}/dadoo/dadoo"
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

    local tmpDir=$(mktemp -d -p /tmp "build-containerd-XXXX")

    rsync -aq "$source/" "$tmpDir"
    pushd "$source" || exit
    bosh sync-blobs
    local containerd_tarball="$(ls ./blobs/containerd/containerd-*.tar.gz)"
    tar xzf "$containerd_tarball" --strip-components=1
    mv -f ctr "${target}/ctr"
    mv -f containerd "${target}/containerd"
    mv -f containerd-shim-runc-v2 "${target}/containerd-shim-runc-v2"

    popd || exit
    rm -rf "$tmpDir"

    cat > "${target}/run.bash" << EOF
export CONTAINERD_BINARY="\$PWD/${built_dir}/containerd/containerd"
export CONTAINERD_SHIM_RUNC_V2_BINARY="\$PWD/${built_dir}/containerd/containerd-shim-runc-v2"
export CONTAINERD_CTR_BINARY="\$PWD/${built_dir}/containerd/ctr"
EOF
}
