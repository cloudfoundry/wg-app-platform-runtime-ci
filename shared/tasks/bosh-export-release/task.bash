#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"
unset THIS_FILE_DIR

deployment_name="export-release-$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 5 ; echo '')"

function run(){
  local task_tmp_dir="${1:?provide temp dir for task}"
  shift 1

  pushd $DIR > /dev/null
  bosh_target
  popd > /dev/null

  pushd repo > /dev/null
  local release_name=$(bosh_release_name)
  popd > /dev/null

  local release_version=$(bosh deployments --json | jq -r --arg name "cf" '(first(.Tables[0].Rows[]? | select(.name == $name)) // .Tables[0].Rows[0]? // {}) | .release_s' |sed 's/\\n/\n/g' | grep "$release_name" |  cut -d'/' -f2)

  if [[ -z "$release_version" ]]; then
    echo "ERROR: Could not find release '$release_name'." >&2
    exit 1
  fi
  echo "release version: ${release_version}"

  local release="${release_name}/${release_version}"

  local stemcell=$(bosh stemcells --json | jq -r --arg os "${OS}" '.Tables[].Rows[] | select(.os | contains($os)) | select(.version | contains("*")) | .os + "/" + .version' | tr -d "*" | sort -V | tail -1)

  echo "Cleaning up previous deployment"
  bosh -d "${deployment_name}" delete-deployment -n

  echo "Deploying $release with stemcell $stemcell"
  local deployment_manifest="${task_tmp_dir}/${deployment_name}.yml"
  cat << EOF > "${deployment_manifest}"
name: "${deployment_name}"
releases:
- name: ${release_name}
  version: ${release_version}

stemcells:
- alias: default
  os: "$(echo $stemcell | cut -d '/' -f1)"
  version: "$(echo $stemcell | cut -d '/' -f2)"

instance_groups: []

update:
  canaries: 1
  max_in_flight: 1
  canary_watch_time: 1000-90000
  update_watch_time: 1000-90000
EOF
bosh -d ${deployment_name} -n deploy ${deployment_manifest}


debug "Running 'bosh export-release -d ${deployment_name} ${release} ${stemcell}'"
bosh export-release -d "${deployment_name}" "${release}" "${stemcell}"
}

function cleanup() {
  bosh -d "${deployment_name}" -n deld
  rm -rf "${task_tmp_dir}"
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run $task_tmp_dir "$@"
