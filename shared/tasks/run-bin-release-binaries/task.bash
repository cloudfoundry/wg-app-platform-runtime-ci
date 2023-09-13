#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR

function run(){
    local task_tmp_dir="${1:?provide temp dir for task}"
    shift 1

    git_safe_directory 

    local version
    version="$(cat version/version)"

    pushd "repo/$DIR"  > /dev/null

    debug "Releasing $(get_git_remote_name) version ${version}"
    
    IFS=$'\n'
    for arch in ${ARCH}; do
        for os in ${OS}; do
            debug "Running release-binaries for Arch (${arch}) and Os (${os})"
            ./bin/release-binaries.bash "${arch}" "${os}" "${version}" "${task_tmp_dir}" 
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
