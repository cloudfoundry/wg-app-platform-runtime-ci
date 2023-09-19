#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/git-helpers.bash"
unset THIS_FILE_DIR

function run() {
    git_configure_safe_directory
    pushd repo > /dev/null
    bundle install
    debug "Running bundle exec rspec spec $(git_get_remote_name):"
    bundle exec rspec spec
    popd > /dev/null
}

trap 'err_reporter $LINENO' ERR
run "$@"
