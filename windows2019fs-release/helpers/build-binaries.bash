function build_hydrator(){
    local source="${1?Provide source dir}"
    local target="${2?Provide target dir}"

    verify_go

    local built_dir=$(basename "${target}")
    target="$target/hydrator"
    mkdir -p "${target}"

    pushd "$source" || exit
    go build -o "${target}/run" .
    popd || exit

    cat > "${target}/run.bash" << EOF
export HYDRATOR_BINARY="\$PWD/${built_dir}/hydrator/run"
EOF
}
