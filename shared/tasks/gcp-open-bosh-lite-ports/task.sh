#!/bin/bash

set -eu -o pipefail

# ENV
: "${BBL_STATE_DIR:?}"
: "${SERVICE_ACCOUNT_KEY:?}"
: "${PROJECT:?}"

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../../" && pwd )"
bbl_state_dir="${workspace_dir}/bbl-state/${BBL_STATE_DIR}"

tmp_dir="$(mktemp -d /tmp/open-bosh-lite-ports.XXXXXXXX)"
trap '{ rm -rf "${tmp_dir}"; }' EXIT

open_bosh_lite_ports() {
  service_key_path="${tmp_dir}/gcp.json"
  echo "${SERVICE_ACCOUNT_KEY}" > "${service_key_path}"
  gcloud auth activate-service-account --key-file="${service_key_path}"
  gcloud config set project "${PROJECT}"

  tf_state_path="${bbl_state_dir}/vars/terraform.tfstate"
  director_tag="$(jq -r .outputs.director__tags.value[0] "${tf_state_path}")"
  director_network="$(jq -r .outputs.network.value "${tf_state_path}")"

  firewall_rule_name="${director_tag}-${director_network}-bosh-lite"

  if ! gcloud compute firewall-rules describe "${firewall_rule_name}"; then
    gcloud compute firewall-rules \
      create "${firewall_rule_name}" \
      --allow=tcp:80,tcp:443,tcp:2222,tcp:1024-1123 \
      --source-ranges 0.0.0.0/0 \
      --target-tags "${director_tag}" \
      --network "${director_network}"
  fi
}

pushd "${bbl_state_dir}" > /dev/null
  open_bosh_lite_ports
popd > /dev/null
