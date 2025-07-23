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
    modify
}

function modify() {
    current_state="pipeline-state/pipeline-state"
    new_state="updated-pipeline-state/pipeline-state"
    task_tmp_dir=$(mktemp -d -t 'manage-pipeline-state-XXXX')
    tmpfile="$(mktemp -p "${task_tmp_dir}" -t 'new-state-XXXX.json')"

    echo "Current state"
    cat "${current_state}" > "${tmpfile}"
    cat "${tmpfile}"

    selector=$(get_selector)
    echo "Selector for command ${COMMAND}: ${selector}"
    
    echo "Current result of selector:"
    cat < "${current_state}" | jq -r ''"${selector}"''

    new_value="$(get_new_value)"
    echo "Setting ${selector} to ${new_value}"
    cat < "${current_state}" | jq --arg newval "${new_value}" ''"${selector}"' |= $newval' > "${tmpfile}"
    
    echo "New result:"
    cat "${tmpfile}"

    cat "${tmpfile}" > "${new_state}"

    echo "New state:"
    cat "${new_state}"
}

function get_new_value() {
  local new_value="${STATE}"

  if [[ "${COMMAND}" == "claim" ]]; then
    new_value="claimed"
  elif [[ "${COMMAND}" == "unclaim" ]]; then
    new_value="unclaimed"
  fi

  echo "${new_value}"
}

function get_selector() {
  local selector="."

  if [[ "${COMMAND}" == "claim" || "${COMMAND}" == "unclaim" ]]; then
    selector=".env"
  elif [[ "${COMMAND}" == "update-job" ]]; then
    selector=".jobs.${JOB}"
  elif [[ "${COMMAND}" == "acceptance" ]]; then
    selector=".acceptance.${TEST}"
  fi

  echo "${selector}"
}

trap 'err_reporter $LINENO' ERR
run "$@"
