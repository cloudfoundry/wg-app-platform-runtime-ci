#!/bin/bash

function verify_go(){
    pushd "${1}" >/dev/null
    go version
    popd > /dev/null
}
function verify_go_version_match_bosh_release(){
    pushd "${1}" >/dev/null
    local go_version="$(go version | cut -d " " -f 3 | sed 's/go//')"
    local golang_release_dir="$(mktemp -d -t XXX-golang_release_dir)"
    local package_path=$(find ./packages/ -name "golang-*linux" -type d)
    local package_name=$(basename "${package_path}")
    local spec_lock_value=$(yq .fingerprint "${package_path}/spec.lock")
    git clone --quiet https://github.com/bosh-packages/golang-release "${golang_release_dir}" > /dev/null
    local bosh_release_go_version=$("${golang_release_dir}/scripts/get-package-version.sh" "${spec_lock_value}" "${package_name}")
    rm -rf  "${golang_release_dir}"
    if [[ "$(echo $go_version | cut -d '.' -f1,2)" != "$(echo $bosh_release_go_version | cut -d '.' -f1,2)" ]]; then
        echo "Mismatch between container go version ($go_version) and bosh release's go version ($bosh_release_go_version). Please make sure the two match on major and minor"
        exit 1
    fi
    popd > /dev/null
}
function verify_gofmt(){
    pushd "${1}" >/dev/null
    files=$(gofmt -l . | grep -v vendor || true) && [ -z "$files" ]
    popd > /dev/null
}
function verify_govet(){
    pushd "${1}" >/dev/null
    go vet ./...
    popd > /dev/null
}

function expand_flags(){
    debug "expand_flags Starting"
    local list=""
    IFS=$'\n'
    for entry in ${FLAGS}
    do
        list="${list}${entry} "
    done
    debug "running with flags: ${list}"
    debug "expand_flags Ending"
    echo "${list}"
}

function expand_envs(){
    local env_file="${1?path to env file}"
    debug "expand_envs Starting"
    IFS=$'\n'
    for entry in ${ENVS}
    do
        local key=$(echo $entry | cut -d '=' -f1)
        local value=$(echo $entry | cut -d '=' -f2)
        echo "Setting env: $key=$value"
        echo "export $key=$value" >> "${env_file}"
    done
    debug "expand_envs Ending"
}

function expand_functions(){
    debug "expand_functions Starting"
    IFS=$'\n'
    debug "Bash functions to source: ${FUNCTIONS}"
    for entry in ${FUNCTIONS}
    do
        echo "Sourcing: $entry"
        source $entry
    done
    debug "expand_functions Ending"
}

function expand_verifications(){
    debug "expand_verifications Starting"
    for entry in ${VERIFICATIONS}
    do
        echo "Verifying: $entry"
        eval "$entry"
    done
    debug "expand_verifications Ending"
}

function debug(){
    echo "${@}" >> "/tmp/$TASK_NAME.log"
}

function init_git_author(){
    git config --global user.name "${GIT_COMMIT_USERNAME:=App Platform Runtime Working Group CI Bot}"
    git config --global user.email "${GIT_COMMIT_EMAIL:=app+platform+runtime+wg+ci@vmware.com}"
}

function get_git_remote_name() {
    basename $(git remote get-url origin)
}

function err_reporter() {
    echo "---Debug Report Starting--"
    cat "/tmp/$TASK_NAME.log"
    echo "---Debug Report Ending--"
}

