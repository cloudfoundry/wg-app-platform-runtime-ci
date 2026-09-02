#!/bin/bash
set -euo pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/git-helpers.bash"
unset THIS_FILE_DIR

SENTINEL_PATH="${BBL_STATE_DIR}/ci-status/${SENTINEL_FILE}"
INTERVAL=300

cp -r env/. updated-env/

if [[ -n "${TIMEOUT_SECONDS:-}" && "${TIMEOUT_SECONDS}" -gt 0 ]]; then
  eval "$(ssh-agent -s)"
  echo "${GITHUB_PRIVATE_KEY}" | ssh-add -
  ssh-keyscan "${GITHUB_HOST}" >> ~/.ssh/known_hosts 2>/dev/null

  DEADLINE=$(( $(date +%s) + TIMEOUT_SECONDS ))

  while true; do
    git -C updated-env fetch origin

    if git -C updated-env cat-file -e "origin/main:${SENTINEL_PATH}" 2>/dev/null; then
      echo "${SENTINEL_FILE} sentinel detected - skipping write."
      git -C updated-env reset --hard origin/main
      exit 0
    fi

    NOW=$(date +%s)
    if [[ "${NOW}" -ge "${DEADLINE}" ]]; then
      echo "Timeout of ${TIMEOUT_SECONDS}s reached, writing ${SENTINEL_FILE} sentinel..."
      break
    fi

    REMAINING=$(( DEADLINE - NOW ))
    SLEEP=$(( REMAINING < INTERVAL ? REMAINING : INTERVAL ))
    echo "Sentinel not found yet, sleeping ${SLEEP}s (${REMAINING}s remaining)..."
    sleep "${SLEEP}"
  done

  git -C updated-env reset --hard origin/main
fi

mkdir -p "updated-env/${BBL_STATE_DIR}/ci-status"
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
