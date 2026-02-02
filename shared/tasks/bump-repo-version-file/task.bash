#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/git-helpers.bash"
unset THIS_FILE_DIR

function run(){
    git_configure_author
    git_configure_safe_directory
    export VERSION=$(cat version/version)

    if [[ -d "built-binaries" ]]; then
        IFS=$'\n'
        for entry in $(find built-binaries -name "*.bash");
        do
            echo "Sourcing: $entry"
            debug "$(cat $entry)"
            source "${entry}"
        done
        unset IFS
    fi

    pushd repo > /dev/null
    local private_yml="./config/private.yml"
    bosh_configure_private_yml "$private_yml"

    eval "${BUMP_ACTION}"

    if [[ $(git status --porcelain) ]]; then
        git add -A .
        git commit -m "Bump version to ${VERSION}"
    fi
    rsync -a $PWD/ "../bumped-repo"
    popd > /dev/null
}

trap 'err_reporter $LINENO' ERR
run "$@"
