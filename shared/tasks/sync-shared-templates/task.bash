#!/bin/bash

set -eEux
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/git-helpers.bash"
unset THIS_FILE_DIR

export CURRENT_DIR="$PWD"

function run() {
  git_configure_author
  git_configure_safe_directory

  local CI_DIR="$PWD/ci"
 
  pushd repo > /dev/null
  mkdir -p "${DIR}/.github/ISSUE_TEMPLATE"

  if [[ -f "${CI_DIR}/${PARENT_TEMPLATE_DIR:-undefined}/github/issue-bug.yml" ]]; then
    cp -r "${CI_DIR}/${PARENT_TEMPLATE_DIR}/github/issue-bug.yml" "${DIR}/.github/ISSUE_TEMPLATE/"
  else
    cp -r "${CI_DIR}/shared/github/issue-bug.yml" "${DIR}/.github/ISSUE_TEMPLATE/"
  fi

  if [[ -f "${CI_DIR}/${PARENT_TEMPLATE_DIR:-undefined}/github/issue-enhance.yml" ]]; then
    cp -r "${CI_DIR}/${PARENT_TEMPLATE_DIR}/github/issue-enhance.yml" "${DIR}/.github/ISSUE_TEMPLATE/"
  else
    cp -r "${CI_DIR}/shared/github/issue-enhance.yml" "${DIR}/.github/ISSUE_TEMPLATE/"
  fi

  if [[ -f "${CI_DIR}/${PARENT_TEMPLATE_DIR:-undefined}/github/config.yml" ]]; then
    cp -r "${CI_DIR}/${PARENT_TEMPLATE_DIR}/github/config.yml" "${DIR}/.github/ISSUE_TEMPLATE/"
  else
    cp -r "${CI_DIR}/shared/github/config.yml" "${DIR}/.github/ISSUE_TEMPLATE/"
  fi

  if [[ -f "${CI_DIR}/${PARENT_TEMPLATE_DIR:-undefined}/github/PULL_REQUEST_TEMPLATE.md" ]]; then
    cp -r "${CI_DIR}/shared/${PARENT_TEMPLATE_DIR}/PULL_REQUEST_TEMPLATE.md" "${DIR}/.github"
  else
    cp -r "${CI_DIR}/shared/github/PULL_REQUEST_TEMPLATE.md" "${DIR}/.github"
  fi

  cat > "${DIR}/.github/TEMPLATE-README.md" << EOF
Changing templates
---------------
These templates are synced from [these shared tempaltes](https://github.com/cloudfoundry/wg-app-platform-runtime-ci/tree/main/shared/github).
Each pipeline will contain a \`sync-shared-templates-*\` job for updating the content of these files.
If you would like to modify these, please change them in the shared group.
It's also possible to override the templates on pipeline's parent directory by introducing a custom
template in \'\$PARENT_TEMPLATE_DIR/github/FILENAME\` in CI repo
EOF

  if [[ $(git status --porcelain) ]]; then
    git add -A .
    git commit -m "Sync shared github issue/PR templates"
  fi

  rsync -a $PWD/ "$CURRENT_DIR/synced-repo"

  popd > /dev/null
}

trap 'err_reporter $LINENO' ERR
run "$@"
