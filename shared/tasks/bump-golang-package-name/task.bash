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
    local go_version_file="$PWD/$GO_VERSION_FILE"

    pushd repo > /dev/null

    if ! [[ -f "$go_version_file" ]]; then
        echo "Missing $GO_VERSION_FILE file"
        exit 1
    fi

    if [[ -z "${PLATFORM}" ]]; then
        echo "Missing PLATFORM enviornment variable"
        exit 1
    fi

    local release_name=$(bosh_release_name)
    local go_minor_version=$(cat ${go_version_file} | jq -r "if (.releases.\"${release_name}\" == null) then .default else .releases.\"${release_name}\" end")
    local from_package to_package
    if [[ -n "${PREFIX}" ]]; then
        from_package=$(basename ./packages/$PREFIX-golang-*-${PLATFORM})
        to_package="$PREFIX-golang-${go_minor_version}-${PLATFORM}"
    else
        from_package=$(basename ./packages/golang-*-${PLATFORM})
        to_package="golang-${go_minor_version}-${PLATFORM}"
    fi
    if [[ "${from_package}" != "${to_package}" ]]; then
        echo "Replacing bosh package from:${from_package} to:${to_package}"
        sed -i "s/${from_package}/${to_package}/g" packages/**/spec packages/**/packaging
        # do not match the job name, e.g. golang-1-windows in windows-tools-release
        sed -i "3,\$s/${from_package}/${to_package}/g" jobs/**/spec
        rm -rf "packages/${from_package}"
    fi
    # making sure new package exists for subsequent bosh-vendor-package task1
    mkdir -p "packages/${to_package}"

    rsync -a $PWD/ "../bumped-repo"
    popd > /dev/null

}

trap 'err_reporter $LINENO' ERR
run "$@"
