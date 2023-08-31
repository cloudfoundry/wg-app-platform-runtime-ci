#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR

function run() {
    pushd repo > /dev/null
    bundle install
    debug "Running bundle exec rspec spec $(get_git_remote_name):"
    bundle exec rspec spec
    popd > /dev/null
}

trap 'err_reporter $LINENO' ERR
run "$@"
