#!/bin/bash

set -eEu
set -o pipefail

function fly_status() {
    local target="${1:?Provide a target}"
    local status
    status=(fly -t "${target}" status)
    if [[ ${status} == "1" ]]; then
        fly -t "${target}" login
    fi
}

function run() {
    local task_tmp_dir="${1:?provide temp dir for task}"
    local task="${2:?Provide a task to execute e.g. run-bin-test}"
    local task_definition
    shift 2

    local target=${FLY_TARGET:-shared}
    fly_status "${target}"

    local os ci_dir
    ci_dir="$( cd "$( dirname "${BASH_SOURCE[0]}\.." )" >/dev/null 2>&1 && dirname $PWD)"
    os="${FLY_OS:-linux}"

    local task_path
    if [[ $(find "${ci_dir}" -type d -ipath "*tasks/$task*" | wc -l) != "1" ]]; then
        echo "Unable to find task. Either more than one or no task dir with name ($task) was found"
        exit 1
    fi
    task_path=$(find "${ci_dir}" -type d -ipath "*tasks/$task*")
    if [[ "$os" == "linux" ]]; then
        local image
        image="${FLY_IMAGE:-cloudfoundry/tas-runtime-build}"

        task_definition=$(mktemp -p "${task_tmp_dir}" -t 'XXXXX-linux.yml')
        cp "$task_path/linux.yml" "${task_definition}"
        cat <<EOF >> "${task_definition}"
image_resource:
  type: registry-image
  source:
    repository: $image
EOF
echo "Running task($task_path/linux.yml) with image($image)"
elif [[ "$os" == "windows" ]];then
    task_definition="${task_path}/windows.yml"
    echo "Running task($task_definition)"
else
    echo "Unsupported OS. Provide a valid FLY_OS"
    exit 1
    fi

    local task_defaults="${REPO_NAME:-invalid}/default-params/$task/$os.yml"
    local fly_mappings
    if [[ -f "$ci_dir/${task_defaults}" ]]; then
        export DEFAULT_PARAMS="./ci/${task_defaults}"

        local inputs outputs
        inputs=$(cat "$ci_dir/${task_defaults}" |  yq . -o json | jq -r '.inputs | select(.) | to_entries| map("-i "+.key+"="+.value) | join (" ")')
        outputs=$(cat "$ci_dir/${task_defaults}" |  yq . -o json | jq -r '.outputs| select(.)| to_entries| map("-o "+.key+"="+.value) | join (" ")')
        fly_mappings=$(echo $inputs $outputs)
    fi

    local fly_args
    fly_args="-i ci=${ci_dir} ${fly_mappings:-} $*"
    echo "Running fly execute with args (${fly_args})"
    eval "fly -t ${target} execute -c ${task_definition} ${fly_args} --include-ignored"
}

function cleanup() {
    rm -rf "$task_tmp_dir"
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "
    Fly execute a task: e.g. 'fly-exec.bash <task-name> <-i input-01=/tmp/input -o output-02=/tmp/output>'

    Options:

    - Running a simple task with minimal inputs: 'fly-exec.bash lint-ci'
    - Running tests from within a release where REPO_NAME and REPO_PATH are source by .envrc: 'DIR=src/code.cloudfoundry.org/multierror fly-exec.bash run-bin-test'
    - Running tests outside of a release repo: 'REPO_NAME=routing-release REPO_PATH=~/workspace/routing-release DIR=src/code.cloudfoundry.org/multierror fly-exec.bash run-bin-test'
    - Running tasks with custom inputs and outputs: 'fly-exec.bash bosh-export-release -i repo=~/workspace/routing-release -i env=~/workspace/envs/cool-beans'

    Environment variables:
    - FLY_OS: defaults to linux
    - FLY_IMAGE: defaults to cloudfoundry/tas-runtime-build
    - FLY_TARGET: defaults to runtime

    Optional Environment variables:
    - REPO_PATH: loaded by .envrc in each respective repo (used where default-params for the task and repo defines inputs and outputs mapping)
    - REPO_NAME: loaded by .envrc in each respective repo
    
    All Environment variables set when running this script will get passed down to 'fly execute'. This means that if a task requires other environment variables, it can be set here when running this script.

    "
    exit
fi
run "$task_tmp_dir" "$@"
