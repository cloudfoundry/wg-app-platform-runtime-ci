#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR

: "${COMMAND:?Need to set COMMAND}"

commands=("claim" "unclaim" "reset" "update-job" "acceptance")
states=("pass" "fail" "running" "stopped")

function validate() {
  if [[ ! " ${commands[*]} " =~ " ${COMMAND} " ]]; then
    echo "ERROR: ${COMMAND} is not a valid command"
    exit 1
  fi
  
  if [[ -n "${STATE}" ]]; then
    if [[ ! " ${states[*]} " =~ " ${STATE} " ]]; then
      echo "ERROR: ${STATE} is not a valid state"
      exit 1
    fi
  fi

  if [[ "${COMMAND}" == "update-job" ]]; then
    if [[ -z "${JOB}" ]]; then
      echo "ERROR: ${COMMAND} must have a JOB specified"
      exit 1
    fi
    if [[ -z "${STATE}" ]]; then
      echo "ERROR: ${COMMAND} must have a STATE specified"
      exit 1
    fi
  fi

  if [[ "${COMMAND}" == "acceptance" ]]; then
    if [[ -z "${TEST}" ]]; then
      echo "ERROR: ${COMMAND} must have a TEST specified"
      exit 1
    fi
    if [[ -z "${STATE}" ]]; then
      echo "ERROR: ${COMMAND} must have a STATE specified"
      exit 1
    fi
  fi
}

function run() {
    validate
    current_state="pipeline-state/pipeline-state"
    task_tmp_dir=$(mktemp -d -t '/tmp/manage-pipeline-state-XXXX')
    tmpfile="$(mktemp -p "${task_tmp_dir}" -t 'new-state-XXXX.json')"

    echo "Current state"
    cat "${current_state}" > "${tmpfile}"
    cat "${tmpfile}"

    local selector=$(get_selector)
    echo "Selector for command ${COMMAND}: ${selector}"
    
    echo "Current result of selector:"
    cat "${current_state}" | jq -r ''"${selector}"''

    echo "Setting ${selector} to 'claimed'"
    cat "${current_state}" | jq --arg newval "claimed" ''"${selector}"' |= $newval' > "${tmpfile}"
    
    echo "New result:"
    cat "${tmpfile}"
}

function get_selector() {
  local selector="."
  if [[ "${COMMAND}" == "claim" || "${COMMAND}" == "unclaim" ]]; then
    selector=".env"
  fi

  echo $selector
}

trap 'err_reporter $LINENO' ERR
run "$@"
