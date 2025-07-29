#!/bin/bash

set -eEu
set -o pipefail
set +x

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR

: "${SERVICE_ACCOUNT_KEY:?Need to set SERVICE_ACCOUNT_KEY}"
: "${COMMAND:?Need to set COMMAND}"
: "${BUCKET:?Need to set BUCKET}"
: "${STATE_PATH:?Need to set STATE_PATH}"
: "${DEBUG:=false}"

commands=("claim" "unclaim" "reset" "update-job" "acceptance" "lock" "unlock" "cleanup" "preserve")
states=("pass" "fail" "running" "pending")
task_tmp_dir=$(mktemp -d -t 'manage-pipeline-state-XXXX')
updatefile="$(mktemp -p "${task_tmp_dir}" -t 'new-state-XXXX.json')"
workingfile="$(mktemp -p "${task_tmp_dir}" -t 'working-XXXX.json')"
state_path="gs://${BUCKET}/${STATE_PATH}"
cleanup_path="gs://${BUCKET}/${STATE_PATH}-cleanup"

statelock="state-lock"

function validate() {
  if [[ ! " ${commands[*]} " =~ " ${COMMAND} " ]]; then
    echo "ERROR: ${COMMAND} is not a valid command"
    echo "Valid commands include: ${commands[*]}"
    exit 1
  fi
  
  if [[ -n "${STATE}" ]]; then
    if [[ ! " ${states[*]} " =~ " ${STATE} " ]]; then
      echo "ERROR: ${STATE} is not a valid state"
      echo "Valid states include: ${states[*]}"
      exit 1
    fi
  fi

  if [[ "${COMMAND}" == "reset" ]] || [[ "${COMMAND}" == "cleanup" ]]; then
    if [[ -z "${ACCEPTANCE_JOBS}" ]]; then
      echo "ERROR: ${COMMAND} must have ACCEPTANCE_JOBS specified"
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
  login
  get_current_state
  validate
  perform_update
}

function perform_update() {
  if [[ "${COMMAND}" == "reset" ]]; then
    reset_state
  elif [[ "${COMMAND}" == "lock" ]]; then
    lock_state
  elif [[ "${COMMAND}" == "unlock" ]]; then
    unlock_state
  elif [[ "${COMMAND}" == "check" ]]; then
    check_state
  elif [[ "${COMMAND}" == "preserve" ]]; then
    preserve_env
  elif [[ "${COMMAND}" == "cleanup" ]]; then
    do_cleanup
    exit 0
  else
    ensure_objects
    modify_state
  fi

  upload_to_gcs
}

function get_current_state() {
  gcloud storage cp "${state_path}" "${workingfile}"
}

function upload_to_gcs() {
  gcloud storage cp "${workingfile}" "${state_path}"
}

function do_cleanup() {
  reset_state 
  touch_cleanup
}

function touch_cleanup() {
  cleanupfile="$(mktemp -p "${task_tmp_dir}" -t 'cleanup-XXXX.json')"
  gcloud storage cp "${cleanupfile}" "${cleanup_path}"
}

function login() {
  keyfile="$(mktemp -p "${task_tmp_dir}" -t 'key-XXXX.json')"
  echo "${SERVICE_ACCOUNT_KEY}" > "${keyfile}"

  gcloud auth activate-service-account --key-file "${keyfile}"
}

function wait_for_lock() {
  lock_selector="$(get_selector "${statelock}")"
  # use -r here because we actually want to compare the value
  locked=$(jq -r ''"${lock_selector}"'' "${workingfile}")
  if [[ "${locked}" == "true" ]]; then
    echo "State is currently being modified. Waiting..."
    while [[ "${locked}" == "true" ]]; do
      echo "."
      sleep 10
      get_current_state
      locked="$(jq -r ''"${lock_selector}"'' "${workingfile}")"
    done
  fi
}

function lock_state() {
  lock_selector="$(get_selector "${statelock}")"
  edit_selection "${lock_selector}" "true"
}

function unlock_state() {
  lock_selector="$(get_selector "${statelock}")"
  edit_selection "${lock_selector}" "false"
}

function reset_state() {
  # bypasses lock intentionally
  echo "Resetting pipeline state..."

  if [[ "${DEBUG}" == "true" ]]; then
    echo "Original state:"
    cat "${workingfile}"
  fi

  echo "{}" > "${workingfile}"

  ensure_entry "env" "unclaimed"
  ensure_entry "preserve" "false"
  ensure_entry "${statelock}" "false"
  ensure_objects
}

function preserve_env() {
  preserve_selector="$(get_selector "preserve")"
  edit_selection "${preserve_selector}" "true"
}

function modify_state() {
  wait_for_lock
  lock_state

  if [[ "${DEBUG}" == "true" ]]; then
    echo "Original state"
    cat "${workingfile}"
  fi

  command_selector=$(get_command_selector)

  if [[ "${DEBUG}" == "true" ]]; then
    echo "Result of ${COMMAND} selector ${command_selector}:"
    jq -r ''"${command_selector}"'' "${workingfile}"
  fi

  new_state="$(get_new_state)"
  edit_selection "${command_selector}" "${new_state}"

  unlock_state
}

function edit_selection() {
  # only use this for selectors retrieved from get_selector
  edit_selector="${1}"
  new_value="${2}"
  jq --arg newval "${new_value}" ''"${edit_selector}"' |= $newval' "${workingfile}" > "${updatefile}"
  mv "${updatefile}" "${workingfile}"
}

function ensure_entry() {
  local entry="${1?:Must set entry for ensure_entry}"
  local value="${2:=""}"
  entry_selector="$(get_selector "${entry}")"
  found_entry=$(jq -r ''"${entry_selector}"'' "${workingfile}")

  if [[ -z "${found_entry}" || "${found_entry}" == "null" ]]; then
    echo "${entry} not found...creating"
    entrytmpfile="$(mktemp -p "${task_tmp_dir}" -t ''"${entry}"'tmp-XXXX.json')"
    jq --arg newval "${value}" ''"${entry_selector}"' = $newval' "${workingfile}" > "${entrytmpfile}"
    mv "${entrytmpfile}" "${workingfile}"
  fi
}

function ensure_objects() {
  ensure_object "jobs"
  ensure_object_entry "jobs" "claim-env"
  ensure_object_entry "jobs" "prepare-env"
  
  ensure_object "acceptance"
  readarray -t acceptance_array <<< "${ACCEPTANCE_JOBS[@]}"
  for acceptance_job in "${acceptance_array[@]}"; do
    ensure_object_entry "acceptance" "${acceptance_job}"
  done
}

function ensure_object() {
  local value="${1?:Must set object name for ensure_object}"
  object_selector="$(get_selector "${value}")"
  current_object=$(jq -r ''"${object_selector}"'' "${workingfile}")

  if [[ -z "${current_object}" ]] || [[ "${current_object}" == "null" ]]; then
    echo "${value} not found...creating"
    objecttmpfile="$(mktemp -p "${task_tmp_dir}" -t ''"${value}"'tmp-XXXX.json')"
    jq ''"${object_selector}"' |= {}' "${workingfile}" > "${objecttmpfile}"
    mv "${objecttmpfile}" "${workingfile}"
  fi
}

function ensure_object_entry() {
  local object="${1?:Must set object name for ensure_object_entry}"
  local entry="${2?:Must set entry for ensure_object_entry}"
  check_selector="$(get_selector "${object}" "${entry}")"
  add_selector="${check_selector} = \"pending\""

  found_entry="$(jq -r ''"${check_selector}"'' "${workingfile}")"

  if [[ -z "${found_entry}" ]] || [[ "${found_entry}" == "null" ]]; then
    echo "${object}[${entry}] not found...creating"
    entrytmpfile="$(mktemp -p "${task_tmp_dir}" -t ''"${entry}"'tmp-XXXX.json')"
    jq ''"${add_selector}"'' "${workingfile}" > "${entrytmpfile}"
    mv "${entrytmpfile}" "${workingfile}"
  fi
}

function get_new_state() {
  local new_state="${STATE}"

  if [[ "${COMMAND}" == "claim" ]]; then
    new_state="claimed"
  elif [[ "${COMMAND}" == "unclaim" ]]; then
    new_state="unclaimed"
  fi

  echo "${new_state}"
}

function get_selector() {
  local selector="${1:-""}"
  local sub_selector="${2:-""}"

  if [[ "${selector}" =~ "-" ]]; then
    selector="\"${selector}\""
  fi

  if [[ "${sub_selector}" =~ "-" ]]; then
    selector="${selector}[\"${sub_selector}\"]"
  fi

  echo ".${selector}"
}

function get_command_selector() {
  local selector="."
  if [[ "${COMMAND}" == "claim" || "${COMMAND}" == "unclaim" ]]; then
    selector="$(get_selector "env")"
  elif [[ "${COMMAND}" == "update-job" ]]; then
    selector="$(get_selector "jobs" "${JOB}")"
  elif [[ "${COMMAND}" == "acceptance" ]]; then
    selector="$(get_selector "acceptance" "${TEST}")"
  fi
  
  echo "${selector}"
}

function check_state() {
  claim_selector="$(get_selector "claim-env")"
  claim_completed="$(has_completed "${claim_selector}")"
  if [[ "${claim_completed}" == "false" ]]; then
    exit 0
  fi

  prepare_selector="$(get_selector "prepare-env")"
  prepare_completed="$(has_completed "${prepare_selector}")"
  if [[ "${prepare_completed}" == "false" ]]; then
    exit 0
  else
    prepare_status="$(job_status "${prepare_selector}")"
    if [[ "${prepare_status}" == "fail" ]]; then
      # what to do here? don't necessarily want to clean up because
      # the env can be reused, but don't want to keep things running either
      # state will no longer be updated because there's nothing running
      # probably need an alert on prepare-env failures

      true # do nothing for now, and we don't care about pass
    fi
  fi

  something_failed="false"
  readarray -t acceptance_array <<< "${ACCEPTANCE_JOBS[@]}"
  for acceptance_job in "${acceptance_array[@]}"; do
    if [[ "${acceptance_job}" == "export-release" ]]; then
      continue # part of acceptance, but after other tests
    fi

    accept_selector="$(get_selector "acceptance" "${acceptance_job}")"
    accept_completed="$(has_completed "${accept_selector}")"

    if [[ "${accept_completed}" == "false" ]]; then
      exit 0
    else
      accept_status="$(job_status "${accept_selector}")"
      if [[ "${accept_status}" == "fail" ]]; then
        something_failed="true"
      fi
    fi
  done

  # only run this while export-release is dependent on other acceptance tests
  if false; then
    export_release_selector="$(get_selector "acceptance" "export-release")"
    export_release_completed="$(has_completed "${export_release_selector}")"
    export_release_status="$(job_status "${export_release_selector}")"

    if [[ "${export_release_completed}" == "true" ]]; then
      do_cleanup
      exit 0
    fi

    # if any acceptance tests have failed, then export-release will not run
    if [[ "${something_failed}" == "true" ]]; then
      preserved="$(is_env_preserved)"
      if [[ "${preserved}" == "false" ]]; then
        do_cleanup
      fi
    fi
  fi
}

function job_status() {
  job_status_selector="${1:?Must set a selector for job_status}"
  result="$(jq -r ''"${job_status_selector}"'' "${workingfile}")"
  echo "${result}"
}

function is_env_preserved() {
  preserve_selector="$(get_selector "preserve")"
  result="$(jq -r ''"${preserve_selector}"'' "${workingfile}")"
  echo "${result}"
}

function has_completed() {
  completed_selector="${1:?Must set a selector for has_completed}"
  result="$(jq -r ''"${completed_selector}"'' "${workingfile}")"

  if [[ "${result}" == "pass" ]] || [[ "${result}" == "fail" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

function cleanup() {
  rm -rf "${task_tmp_dir}"
}

trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run "$@"
