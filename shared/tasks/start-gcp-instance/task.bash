#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"

echo "${SERVICE_ACCOUNT_JSON}" /tmp/config.json

gcloud auth activate-service-account --key-file /tmp/config.json
gcloud compute instances start "${INSTANCE_NAME}" --zone "${ZONE}"
