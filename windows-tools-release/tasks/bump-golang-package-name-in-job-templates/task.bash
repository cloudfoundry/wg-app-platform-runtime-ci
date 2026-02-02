#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TASK_NAME="$(basename "$THIS_FILE_DIR")"
export TASK_NAME
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/git-helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"
unset THIS_FILE_DIR

function run() {
    local go_version_file="${PWD}/${GO_VERSION_FILE}"

    pushd repo > /dev/null

    if ! [[ -f "$go_version_file" ]]; then
        echo "Missing $GO_VERSION_FILE file"
        exit 1
    fi

    local release_name
    release_name=$(bosh_release_name)

    local go_minor_version
    go_minor_version=$(cat ${go_version_file} | jq -r "if (.releases.\"${release_name}\" == null) then .default else .releases.\"${release_name}\" end")

    sed_cmd="sed -i -E 's/golang-(.*)-windows/golang-${go_minor_version}-windows/g' jobs/*/templates/*"
    eval "${sed_cmd}"
    rsync -a "${PWD}/" "../bumped-repo"
    popd > /dev/null

}

trap 'err_reporter $LINENO' ERR
run "$@"
