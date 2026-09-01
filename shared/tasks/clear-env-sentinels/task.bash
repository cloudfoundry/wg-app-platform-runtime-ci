#!/bin/bash
set -euo pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/git-helpers.bash"
unset THIS_FILE_DIR

SENTINEL_DIR="${BBL_STATE_DIR}/ci-status"

cp -r env/. updated-env/

pushd updated-env
  git_configure_author

  if [ -d "${SENTINEL_DIR}" ]; then
    git rm -rf --ignore-unmatch "${SENTINEL_DIR}"
    if git diff --cached --quiet; then
      echo "No sentinels to clear."
    else
      git commit -m "ci: clear ci-status sentinels for new run in ${BBL_STATE_DIR}"
    fi
  else
    echo "No ci-status directory found, nothing to clear."
  fi
popd
