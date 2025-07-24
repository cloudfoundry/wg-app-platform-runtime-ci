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
original_state="pipeline-state/pipeline-state"
new_state="updated-pipeline-state/pipeline-state"
task_tmp_dir=$(mktemp -d -t 'manage-pipeline-state-XXXX')
resultfile="$(mktemp -p "${task_tmp_dir}" -t 'new-state-XXXX.json')"
workingfile="$(mktemp -p "${task_tmp_dir}" -t 'working-XXXX.json')"

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
  if [[ "${COMMAND}" == "reset" ]]; then
    reset
  else
    ensure_objects
    modify
  fi
}

function reset() {
  echo "Resetting pipeline state..."
  ensure_entry "env"

  ensure_object "jobs"
  ensure_object_entry "jobs" "claim-env"
  ensure_object_entry "jobs" "prepare-env"
  
  ensure_object "acceptance"
  # get acceptance tests from index.yml and set here
  ensure_object_entry "acceptance" "run-cats"
  ensure_object_entry "acceptance" "run-wats"
  ensure_object_entry "acceptance" "run-vizzini"
  ensure_object_entry "acceptance" "export-release"
  ensure_object_entry "acceptance" "run-bosh-restart"
  
  echo "Working state:"
  cat "${workingfile}"

  cat "${workingfile}" > "${new_state}"

  echo "Reset state:"
  cat "${new_state}"
}

function modify() {
  echo "Original state"
  cat "${original_state}"

  echo "Working state"
  cat "${workingfile}"

  selector=$(get_selector)
  echo "Selector for command ${COMMAND}: ${selector}"

  echo "Current result of selector:"
  jq -r ''"${selector}"'' "${workingfile}"

  new_value="$(get_new_value)"
  echo "Setting ${selector} to ${new_value}"
  jq --arg newval "${new_value}" ''"${selector}"' |= $newval' "${workingfile}" > "${resultfile}"

  echo "New result:"
  cat "${resultfile}"

  cat "${resultfile}" > "${new_state}"

  echo "New state:"
  cat "${new_state}"
}

function ensure_entry() {
  local entry="${1?:Must set entry for ensure_entry}"
  local selector=".${entry}"
  found_entry=$(jq ''"${selector}"'' "${workingfile}")

  if [[ "${found_entry}" == "null" ]]; then
    echo "${entry} not found...creating"
    entrytmpfile="$(mktemp -p "${task_tmp_dir}" -t ''"${value}"'tmp-XXXX.json')"
    jq ''"${selector}"'' "${workingfile}" > "${entrytmpfile}"
    mv "${entrytmpfile}" "${workingfile}"
  fi
}

function ensure_objects() {
  cat "${original_state}" > "${workingfile}"

  local object="jobs"
  ensure_object "${object}"

  local entry="claim-env"
  ensure_object_entry "${object}" "${entry}"
  entry="prepare-env"
  ensure_object_entry "${object}" "${entry}"

  local object="acceptance"
  ensure_object "${object}"
  # set acceptance tests in index.yml and feed into pipeline for passthrough to this task
  entry="run-cats"
  ensure_object_entry "${object}" "${entry}"
}

function ensure_object() {
  local value="${1?:Must set object name for ensure_object}"
  selector=".${value}"
  current_object=$(jq ''"${selector}"'' "${workingfile}")

  if [[ "${current_object}" == "null" ]]; then
    echo "${value} not found...creating"
    objecttmpfile="$(mktemp -p "${task_tmp_dir}" -t ''"${value}"'tmp-XXXX.json')"
    jq ''"${selector}"' |= {}' "${workingfile}" > "${objecttmpfile}"
    mv "${objecttmpfile}" "${workingfile}"
  fi
}

function ensure_object_entry() {
  local object="${1?:Must set object name for ensure_object_entry}"
  local entry="${2?:Must set entry for ensure_object_entry}"
  check_selector=".${object}[\"${entry}\"]"
  add_selector=".${object}[\"${entry}\"] = \"\""

  found_entry="$(jq ''"${check_selector}"'' "${workingfile}")"

  if [[ "${found_entry}" == "null" ]]; then
    echo "${object}[${entry}] not found...creating"
    entrytmpfile="$(mktemp -p "${task_tmp_dir}" -t ''"${entry}"'tmp-XXXX.json')"
    jq ''"${add_selector}"'' "${workingfile}" > "${entrytmpfile}"
    mv "${entrytmpfile}" "${workingfile}"
  fi
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
    selector=".jobs[\"${JOB}\"]"
  elif [[ "${COMMAND}" == "acceptance" ]]; then
    selector=".acceptance[\"${TEST}\"]"
  fi

  echo "${selector}"
}

trap 'err_reporter $LINENO' ERR
run "$@"
