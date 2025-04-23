#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"

echo "${SERVICE_ACCOUNT_KEY}" > /tmp/config.json

if [[ -z "${INSTANCE_NAME}" && -z "${BBL_STATE_DIR}" ]]; then
    echo "Either INSTANCE_NAME or BBL_STATE_DIR must be provided"
    exit 1
fi

gcloud auth activate-service-account --key-file /tmp/config.json

verb="start"
if [[ "${RESUME}" == "true" ]]; then
    verb="resume"
fi

if [[ -n "${INSTANCE_NAME}" ]]; then
gcloud compute instances "${verb}" "${INSTANCE_NAME}" --project "${PROJECT}" --zone "${ZONE}"
fi

if [[ -n "${BBL_STATE_DIR}" ]]; then
    pushd "bbl-state/${BBL_STATE_DIR}"
    PROJECT=$(grep project_id vars/bbl.tfvars | cut -d '"' -f2)
    ZONE=$(jq -r .gcp.zone < bbl-state.json)
    DIRECTOR=$(jq -r .current_vm_cid < vars/bosh-state.json )
    JUMPBOX=$(jq -r .current_vm_cid < vars/jumpbox-state.json )
    gcloud compute instances "${verb}" "${DIRECTOR}" --project "${PROJECT}" --zone "${ZONE}"
    gcloud compute instances "${verb}" "${JUMPBOX}" --project "${PROJECT}" --zone "${ZONE}"
fi
