#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR

# fragile for loops on find
# shellcheck disable=SC2044 

function run() {
    pushd ci >> /dev/null

    image_resource
    task_params_match
    extra_inputs_match
    metadata_checks
    allowed_task_files
    allowed_dirs
    run_platform_match

    popd > /dev/null

    if [[ ${FOUND_ERROR} == true ]]; then
        throw
    fi
}

# image_resource
function image_resource() {
    debug "Running image_resource function"
    for file in $(find . -name "linux.yml" )
    do
        if [[ $(yq .image_resource "${file}") != "null" ]]; then
            echo "Found image_resource in ${file}. Please remove that and use 'image' to inject into the task at runtime."
            FOUND_ERROR=true
        fi
    done

}
function task_params_match() {
    debug "Running task_params_match function"
    local params_expression='.params|select(.)|keys'
    for dir in $(find . -ipath "*tasks/*" -type d)
    do
        if [[ -f "${dir}/linux.yml" ]]; then
            local same
            if [[ "$(diff <(yq ${params_expression} "${dir}"/linux.yml) <(yq ${params_expression} "${dir}"/metadata.yml))" != "" ]]; then
                echo "params are not matching for ${dir} task according to metadata.yml and linux.yml"
                FOUND_ERROR=true
            fi
        fi
        if [[ -f "$dir/windows.yml" ]]; then
            local same

            if [[ "$(diff <(yq ${params_expression} "${dir}"/windows.yml) <(yq ${params_expression} "${dir}"/metadata.yml))" != "" ]]; then
                echo "params are not matching for ${dir} task according to metadata.yml and windows.yml"
                FOUND_ERROR=true
            fi
        fi
    done
}

# don't call this one directly from run()
# it is called by extra_inputs_match
function intersect_inputs() {
    local set1=${1}
    local set2=${2}

    IFS=$'\n'
    for set1_input in ${set1}
    do
        local matched=false
        for set2_input in ${set2}
        do
            if [[ "${set1_input}" =~ ${set2_input} ]]; then
                matched=true
            elif [[ "${set2_input}" =~ ${set1_input} ]]; then
                matched=true
            fi
        done

        if [[ ${matched} == false ]]; then
            echo "Could not find ${set1_input} in ${set2} when checking ${set1} " 
            FOUND_ERROR=true
        fi
    done
}
function extra_inputs_match() {
    debug "Running extra_inputs_match function"
    for dir in $(find . -ipath "*tasks/*" -type d)
    do
        if [[ -f "$dir/linux.yml" ]]; then
            local metadata_inputs
            metadata_inputs="$(yq -r '.extra_inputs | select(.) | keys | .[]' "${dir}"/metadata.yml)"
            local optional_inputs
            optional_inputs="$(yq -r '.inputs[] | select(.optional==true) | .name' "${dir}"/linux.yml)"

            intersect_inputs "${metadata_inputs}" "${optional_inputs}"
            intersect_inputs "${optional_inputs}" "${metadata_inputs}" 
        fi
    done
}
function metadata_checks() {
    debug "Running metadata_checks function"
    for file in $(find . -name "metadata.yml")
    do
        if [[ $(yq '.readme' "${file}") == 'null' ]]; then
            echo "No readme found in ${file}"
            FOUND_ERROR=true
        fi

        if [[ $(yq '.oses' "${file}") == 'null' ]]; then
            echo "No oses found in ${file}"
            FOUND_ERROR=true
        fi
    done
}

function allowed_task_files() {
    debug "Running allowed_task_files function"
    local filenames='metadata.yml
    linux.yml
    windows.yml
    task.bash
    task.ps1
    '
    IFS=$'\n'
    for filepath in $(find . -ipath "*tasks/*/*" -type f)
    do
        local file
        file=$(basename "${filepath}")
        # literal regex matching
        # shellcheck disable=2076
        if ! [[ "${filenames[*]}" =~ "${file}" ]]; then
            echo "File ${filepath} is not allowed"
            FOUND_ERROR=true
        fi
    done
}

function allowed_dirs() {
    debug "Running allowed_dirs function"
    local release_list="garden-runc-release|routing-release|winc-release"
    local dir_patterns
    dir_patterns="$(cat <<EOF
^./(shared|$release_list)/helpers$
^./(shared|$release_list)/tasks/[a-z\-]*$
^./($release_list)/(manifests|opsfiles)$
^./($release_list)/default-params/[a-z\-]*$
EOF
)"
IFS=$'\n'
for entry in $(find . -type f | grep -Ev "index.yml|README.md|NOTICE|CODEOWNERS|LICENSE|.git" | xargs dirname | uniq)
do
    local matched=false
    for pattern in $dir_patterns
    do
        if [[ "${entry}" =~ ${pattern} ]]; then
            matched=true
            break
        fi

    done
    if [[ ${matched} == false ]]; then
        echo "Could not find ${entry} in allowed directory patterns" 
        FOUND_ERROR=true
    fi
done
}

function run_platform_match() {
    debug "Running run_platform_match function"
    for dir in $(find . -ipath "*tasks/*" -type d)
    do
        if [[ -f "${dir}/linux.yml" && ! -f "${dir}/task.bash" ]]; then
            echo "Task ${dir} has a Linux config and no Bash file"
            FOUND_ERROR=true
        elif [[ ! -f "${dir}/linux.yml" && -f "${dir}/task.bash" ]]; then
            echo "Task ${dir} has a Bash file and no Linux config"
            FOUND_ERROR=true
        fi

        if [[ -f "${dir}/windows.yml" && ! -f "${dir}/task.ps1" ]]; then
            echo "Task ${dir} has a Windows config and no Powershell file"
            FOUND_ERROR=true
        elif [[ ! -f "${dir}/windows.yml" && -f "${dir}/task.ps1" ]]; then
            echo "Task ${dir} has a Powershell file and no Windows config"
            FOUND_ERROR=true
        fi

        if [[ -f "${dir}/linux.yml" && "$(yq '.oses[] | select(.=="linux")' ${dir}/metadata.yml)" != "linux" ]]; then
            echo "Task $(basename "${dir}") missing missing osses metadata"
            FOUND_ERROR=true
        elif [[ ! -f "${dir}/linux.yml" && "$(yq '.oses[] | select(.=="linux")' ${dir}/metadata.yml)" == "linux" ]]; then
            echo "Task $(basename "${dir}") missing missing Linux config based on metadata"
            FOUND_ERROR=true
        fi

        if [[ -f "${dir}/windows.yml" && "$(yq '.oses[] | select(.=="windows")' ${dir}/metadata.yml)" != "windows" ]]; then
            echo "Task $(basename "${dir}") missing missing osses metadata"
            FOUND_ERROR=true
        elif [[ ! -f "${dir}/windows.yml" && "$(yq '.oses[] | select(.=="windows")' ${dir}/metadata.yml)" == "windows" ]]; then
            echo "Task ${dir} missing missing Windows config based on metadata"
            FOUND_ERROR=true
        fi
    done
}

trap 'err_reporter $LINENO' ERR
FOUND_ERROR=false
run "$@"
