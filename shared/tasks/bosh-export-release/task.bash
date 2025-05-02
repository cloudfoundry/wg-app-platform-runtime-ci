#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"
unset THIS_FILE_DIR


function run(){
  local task_tmp_dir="${1:?provide temp dir for task}"
  shift 1

  bosh_target
  local deployment_name="export-release-$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 5 ; echo '')"

  pushd repo > /dev/null
  local release_name=$(bosh_release_name)
  popd > /dev/null

  local release_version=$(bosh releases --json | jq --arg name "${release_name}" -r '.Tables[0].Rows[] | select(.name==$name) | .version' | grep '\*' | cut -d'*' -f1)

  if (( $(echo "${release_version}" | wc -l) > 1 )); then
    echo "multiple versions ${release_version} is used with release ${release_name}"
    exit 1
  fi

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
bosh -d "${deployment_name}" -n deld
}

function cleanup() {
  rm -rf "${task_tmp_dir}"
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run $task_tmp_dir "$@"
