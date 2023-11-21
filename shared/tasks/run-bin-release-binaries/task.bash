#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/git-helpers.bash"
unset THIS_FILE_DIR

function run(){
    local task_tmp_dir="${1:?provide temp dir for task}"
    shift 1

    git_configure_safe_directory

    local version

    if [[ -d version ]]; then
        version="$(cat version/version)"
    fi

    if [[ -d built-binaries ]]; then
        export BUILT_BINARIES="$PWD/built-binaries"
    fi

    pushd "repo/$DIR"  > /dev/null

    if [[ "${version:-empty}" == "empty" ]]; then
        version=$(git rev-parse HEAD)
    fi

    debug "Releasing $(git_get_remote_name) version ${version}"
    
    IFS=$'\n'
    for arch in ${ARCH}; do
        for os in ${OS}; do
            if [[ -n "$(go tool dist list | grep ${os}/${arch})" ]]; then
                debug "Running release-binaries for Arch (${arch}) and Os (${os})"
                ./bin/release-binaries.bash "${arch}" "${os}" "${version}" "${task_tmp_dir}" 
            fi
        done
    done

    popd  > /dev/null

    cp -r ${task_tmp_dir}/* ./released-binaries/

}

function cleanup() {
    rm -rf $task_tmp_dir
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run $task_tmp_dir "$@"
