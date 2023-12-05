#!/bin/bash
# fragile for loops on find
# shellcheck disable=SC2044 

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR


function run() {
    pushd ci || return >> /dev/null

    allowed_dirs
    allowed_task_files
    extra_inputs_match
    image_resource
    metadata_checks
    opsfile_metadata
    required_repo_linters
    run_platform_match
    task_params_match
    verify_opsfile_use

    popd || return > /dev/null

    if [[ ${FOUND_ERROR} == true ]]; then
        throw 2>/dev/null #We need a command that doesn't exist so that the script's ERR trap is invoked
    fi
}

# image_resource
function image_resource() {
    debug "Running image_resource function"
    # Ignored tasks define image resource to dynamically load tagged image
    ignored_tasks=("run-bin-test" "build-binaries" "copy-grace-opsfile")

    for file in $(find . -name "linux.yml" )
    do
        task_dir_name="$(basename $(dirname \"${file}\"))"
        if [[ ! "${ignored_tasks[*]}" =~ "${task_dir_name}" ]]; then
            if [[ $(yq .image_resource "${file}") != "null" ]]; then
                debug "Found image_resource in ${file}. Please remove that and use 'image' to inject into the task at runtime."
                FOUND_ERROR=true
            fi
        fi
    done

}
function task_params_match() {
    debug "Running task_params_match function"
    local params_expression='.params|select(.)|keys'
    for dir in $(find . -ipath "*tasks/*" -type d)
    do
        local linux windows metadata
        linux="${dir}/linux.yml"
        windows="${dir}/windows.yml"
        metadata="${dir}/metadata.yml"

        if [[ -f "${linux}" ]]; then
            if [[ "$(diff <(yq ${params_expression} "${linux}") <(yq ${params_expression} "${metadata}"))" != "" ]]; then
                debug "params are not matching for ${dir} task according to metadata.yml and linux.yml"
                FOUND_ERROR=true
            fi
        fi
        if [[ -f "${windows}" ]]; then
            if [[ "$(diff <(yq ${params_expression} "${windows}") <(yq ${params_expression} "${metadata}"))" != "" ]]; then
                debug "params are not matching for ${dir} task according to metadata.yml and windows.yml"
                FOUND_ERROR=true
            fi
        fi
    done
}

# don't call this one directly from run()
# it is called by extra_inputs_match
function intersect_inputs() {
    local set1=${1}
    local set1_name=${2}
    local set2=${3}
    local set2_name=${4}

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
            debug "Could not find ${set1_input} in ${set2_name} when checking ${set1_name}" 
            FOUND_ERROR=true
        fi
    done

    for set2_input in ${set2}
    do
        local matched=false
        for set1_input in ${set1}
        do
            if [[ "${set2_input}" =~ ${set1_input} ]]; then
                matched=true
            elif [[ "${set1_input}" =~ ${set2_input} ]]; then
                matched=true
            fi
        done

        if [[ ${matched} == false ]]; then
            debug "Could not find ${set2_input} in ${set1_name} when checking ${set2_name}" 
            FOUND_ERROR=true
        fi
    done
}
function extra_inputs_match() {
    debug "Running extra_inputs_match function"
    for dir in $(find . -ipath "*tasks/*" -type d)
    do
        local linux windows metadata
        linux="${dir}/linux.yml"
        windows="${dir}/windows.yml"
        metadata="${dir}/metadata.yml"

        local metadata_inputs
        metadata_inputs="$(yq -r '.extra_inputs | select(.) | keys | .[]' "${metadata}")"

        if [[ -f "${linux}" ]]; then
            local optional_inputs_linux
            optional_inputs_linux="$(yq -r '.inputs[] | select(.optional==true) | .name' "${linux}")"

            intersect_inputs "${metadata_inputs}" "metadata inputs" "${optional_inputs_linux}" "${linux}"
        fi
        if [[ -f "${windows}" ]]; then
            local optional_inputs_windows
            optional_inputs_windows="$(yq -r '.inputs[] | select(.optional==true) | .name' "${windows}")"
            intersect_inputs "${metadata_inputs}" "metadata inputs" "${optional_inputs_windows}" "${windows}"
        fi
    done
}
function metadata_checks() {
    debug "Running metadata_checks function"
    for file in $(find . -name "metadata.yml")
    do
        if [[ $(yq '.readme' "${file}") == 'null' ]]; then
            debug "No readme found in ${file}"
            FOUND_ERROR=true
        fi

        if [[ $(dirname "${file}") = *tasks* ]]; then 
            if [[ $(yq '.oses' "${file}") == 'null' ]]; then
                debug "No oses found in ${file}"
                FOUND_ERROR=true
            fi
        fi

        if [[ $(dirname "${file}") = *opsfiles* ]]; then 
            if [[ $(yq '.opsfiles' "${file}") == 'null' ]]; then
                debug "No opsfiles found in ${file}"
                FOUND_ERROR=true
            fi
        fi
    done
}

function allowed_task_files() {
    debug "Running allowed_task_files function"
    local filenames=(
        metadata.yml
        linux.yml
        windows.yml
        task.bash
        task.ps1
    )
    for filepath in $(find . -ipath "*tasks/*/*" -type f)
    do
        local file
        file=$(basename "${filepath}")
        # literal regex matching
        # shellcheck disable=2076
        if ! [[ "${filenames[*]}" =~ "${file}" ]]; then
            debug "File ${filepath} is not allowed"
            debug "Should be one of ${filenames[*]}"
            FOUND_ERROR=true
        fi
    done
}

function allowed_dirs() {
    debug "Running allowed_dirs function"
    local release_list="garden-runc-release|routing-release|winc-release|nats-release|healthchecker-release|cf-networking-release|silk-release|envoy-nginx-release|cpu-entitlement-plugin|diego-release"
    local dir_patterns
    dir_patterns="$(cat <<EOF
^./bin/*$
^./examples/(task|pipeline)*$
^./examples/repo/(scripts-dir-with-db|scripts-dir-generic)$
^./examples/repo/(scripts-dir-with-db|scripts-dir-generic)/docker$
^./(shared|${release_list})/(helpers|opsfiles|linters|manifests|dockerfiles)$
^./(shared|${release_list})/tasks/[a-z\-]*$
^./(${release_list})/(manifests)$
^./(${release_list})/default-params/[a-z\-]*$
^./(${release_list})/dockerfiles/[a-z\-]*$
EOF
)"
IFS=$'\n'
for entry in $(find . -type f | grep -Ev "index.yml|README.md|NOTICE|CODEOWNERS|LICENSE|.git|go-version.json" | xargs dirname | uniq)
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
        debug "Found unexpected directory ${entry}."
        debug "If this should be present, make sure it's added to the allowed_dirs() function in lint-ci/task.bash. Otherwise, remove it."
        FOUND_ERROR=true
    fi
done
}

function run_platform_match() {
    debug "Running run_platform_match function"
    for dir in $(find . -ipath "*tasks/*" -type d | grep -Ev "copy-grace-opsfile")
    do
        if [[ -f "${dir}/linux.yml" && ! -f "${dir}/task.bash" ]]; then
            debug "Task ${dir} has a Linux config and no Bash file"
            FOUND_ERROR=true
        elif [[ ! -f "${dir}/linux.yml" && -f "${dir}/task.bash" ]]; then
            debug "Task ${dir} has a Bash file and no Linux config"
            FOUND_ERROR=true
        fi

        if [[ -f "${dir}/windows.yml" && ! -f "${dir}/task.ps1" ]]; then
            debug "Task ${dir} has a Windows config and no Powershell file"
            FOUND_ERROR=true
        elif [[ ! -f "${dir}/windows.yml" && -f "${dir}/task.ps1" ]]; then
            debug "Task ${dir} has a Powershell file and no Windows config"
            FOUND_ERROR=true
        fi

        if [[ -f "${dir}/linux.yml" && "$(yq '.oses[] | select(.=="linux")' "${dir}/metadata.yml")" != "linux" ]]; then
            debug "Task $(basename "${dir}") missing missing oses metadata"
            FOUND_ERROR=true
        elif [[ ! -f "${dir}/linux.yml" && "$(yq '.oses[] | select(.=="linux")' "${dir}/metadata.yml")" == "linux" ]]; then
            debug "Task $(basename "${dir}") missing missing Linux config based on metadata"
            FOUND_ERROR=true
        fi

        if [[ -f "${dir}/windows.yml" && "$(yq '.oses[] | select(.=="windows")' "${dir}/metadata.yml")" != "windows" ]]; then
            debug "Task $(basename "${dir}") missing missing oses metadata"
            FOUND_ERROR=true
        elif [[ ! -f "${dir}/windows.yml" && "$(yq '.oses[] | select(.=="windows")' "${dir}/metadata.yml")" == "windows" ]]; then
            debug "Task ${dir} missing missing Windows config based on metadata"
            FOUND_ERROR=true
        fi
    done
}

function verify_opsfile_use(){
    debug "Running verify_opsfile_use function"
    for file in $(find . -ipath "*opsfiles/*.yml" ! -name "metadata.yml" -type f)
    do
        local matched=false
        local opsfile
        opsfile=$(basename "${file}")
        for index in $(find . -name "index.yml")
        do
            if [[ $(yq ".opsfiles[] | select(.==\"${opsfile}\")" "${index}") == "${opsfile}" ]]; then
                matched=true
                break;
            fi
        done
        if [[ ${matched} == false ]]; then
            debug "Opsfile ${file} is not used.  Consider removing it." 
            FOUND_ERROR=true
        fi
    done
}

function opsfile_metadata() {
    debug "Running opsfile_metadata function"

    for dir in $(find . -name "opsfiles" -type d)
    do 
        local metadata_file="${dir}/metadata.yml"
        if [[ ! -f "${metadata_file}" ]]; then
            debug "No metadata.yml file found in ${dir}"
            FOUND_ERROR=true
        else
            local metadata_opsfiles dir_opsfiles
            metadata_opsfiles=$(yq '.opsfiles | keys | .[]' "${metadata_file}")
            dir_opsfiles=$(find "${dir}" -ipath "*.yml" ! -name "metadata.yml")

            intersect_inputs "${metadata_opsfiles}" "metadata" "${dir_opsfiles}" "${dir}"
        fi
    done
}

function required_repo_linters() {
    debug "Running required_repo_linters function"
    local required_linters=$(yq '.params.LINTERS' ./shared/tasks/lint-repo/linux.yml)

    for required_linter in ${required_linters}; do
        for dir in $(find . -ipath "*linters" -type d | grep -v shared)
        do
            if ! [[ -f "${dir}/${required_linter}" ]]; then
                if ! [[ -f "./shared/linters/${required_linter}" ]]; then
                    debug "Required linter ${required_linter} was not found in ${dir}"
                    FOUND_ERROR=true
                fi
            fi
        done
    done
    
}

trap 'err_reporter $LINENO' ERR
FOUND_ERROR=false
run "$@"
