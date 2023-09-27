#!/bin/bash

set -eu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CI="${THIS_FILE_DIR}/../../wg-app-platform-runtime-ci"
. "$CI/shared/helpers/git-helpers.bash"
REPO_NAME=$(git_get_remote_name)
REPO_PATH="${THIS_FILE_DIR}/../"
unset THIS_FILE_DIR

IMAGE="cloudfoundry/tas-runtime-build"

if [[ -z "${*}" ]]; then
  ARGS="-it"
else
  ARGS="${*}"
fi

echo $ARGS

docker pull "${IMAGE}"
docker rm -f "$REPO_NAME-docker-container"
docker run -it \
  --env "REPO_NAME=$REPO_NAME" \
  --env "REPO_PATH=/repo" \
  --name "$REPO_NAME-docker-container" \
  -v "${REPO_PATH}:/repo" \
  -v "${CI}:/ci" \
   <REPLACE_ME> or --privileged \ #Needed for releases that need containers with elavated permissions
   <REPLACE_ME> or --cap-add ALL \
  ${ARGS} \
  "${IMAGE}" \
  /bin/bash
  
