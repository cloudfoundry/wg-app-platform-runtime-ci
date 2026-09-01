#!/bin/bash
set -euo pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/git-helpers.bash"
unset THIS_FILE_DIR

SENTINEL_DIR="${BBL_STATE_DIR}/ci-status"
SENTINEL_PATH="${SENTINEL_DIR}/${SENTINEL_FILE}"

cp -r env/. updated-env/

mkdir -p "updated-env/${SENTINEL_DIR}"

date -u > "updated-env/${SENTINEL_PATH}"

pushd updated-env
  git_configure_author

  git add "${SENTINEL_PATH}"

  if git diff --cached --quiet; then
    echo "Sentinel ${SENTINEL_FILE} already present, nothing to commit."
  else
    git commit -m "ci: mark ${SENTINEL_FILE} for ${BBL_STATE_DIR} (${REASON})"
  fi
popd
