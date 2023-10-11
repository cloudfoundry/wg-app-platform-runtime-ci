#!/bin/bash

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$THIS_FILE_DIR/../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR

function build_cpu_entitlement_plugin(){
    local source="${1?Provide source dir}"
    local target="${2?Provide target dir}"

    verify_go

    local built_dir=$(basename "${target}")
    target="$target/cpu-entitlement-plugin"
    mkdir -p "${target}"

    pushd "$source" || exit
    go build -o "${target}/run" .
    popd || exit

    cat > "${target}/run.bash" << EOF
export CPU_ENTITLEMENT_PLUGIN_BINARY="\$PWD/${built_dir}/cpu-entitlement-plugin/run"
EOF
}

function build_cpu_overentitlement_instances_plugin(){
    local source="${1?Provide source dir}"
    local target="${2?Provide target dir}"

    verify_go

    local built_dir=$(basename "${target}")
    target="$target/cpu-overentitlement-instances-plugin"
    mkdir -p "${target}"

    pushd "$source" || exit
    go build -o "${target}/run" .
    popd || exit

    cat > "${target}/run.bash" << EOF
export CPU_OVERENTITLEMENT_INSTANCES_PLUGIN_BINARY="\$PWD/${built_dir}/cpu-overentitlement-instances-plugin/run"
EOF
}
