#!/bin/bash

set -eEu
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
  local CI_CONFIG_DIR="$PWD/ci-config"
  local SYNCED_REPO_DIR="$PWD/synced-repo"
 
  pushd "repo/" > /dev/null
  local git_remote_name=$(git_get_remote_name)
  rm -rf ".github"
  mkdir -p ".github/ISSUE_TEMPLATE"

  if [[ -f "${CI_DIR}/${PARENT_TEMPLATE_DIR:-undefined}/github/issue-bug.yml" ]]; then
    cp -r "${CI_DIR}/${PARENT_TEMPLATE_DIR}/github/issue-bug.yml" ".github/ISSUE_TEMPLATE/"
  elif [[ -f "${CI_CONFIG_DIR}/${PARENT_TEMPLATE_DIR:-undefined}/github/issue-bug.yml" ]]; then
    cp -r "${CI_CONFIG_DIR}/${PARENT_TEMPLATE_DIR}/github/issue-bug.yml" ".github/ISSUE_TEMPLATE/"
  else
    cp -r "${CI_DIR}/shared/github/issue-bug.yml" ".github/ISSUE_TEMPLATE/"
  fi

  if [[ -f "${CI_DIR}/${PARENT_TEMPLATE_DIR:-undefined}/github/issue-enhance.yml" ]]; then
    cp -r "${CI_DIR}/${PARENT_TEMPLATE_DIR}/github/issue-enhance.yml" ".github/ISSUE_TEMPLATE/"
  elif [[ -f "${CI_CONFIG_DIR}/${PARENT_TEMPLATE_DIR:-undefined}/github/issue-enhance.yml" ]]; then
    cp -r "${CI_CONFIG_DIR}/${PARENT_TEMPLATE_DIR}/github/issue-enhance.yml" ".github/ISSUE_TEMPLATE/"
  else
    cp -r "${CI_DIR}/shared/github/issue-enhance.yml" ".github/ISSUE_TEMPLATE/"
  fi

  if [[ -f "${CI_DIR}/${PARENT_TEMPLATE_DIR:-undefined}/github/config.yml" ]]; then
    cp -r "${CI_DIR}/${PARENT_TEMPLATE_DIR}/github/config.yml" ".github/ISSUE_TEMPLATE/"
  elif [[ -f "${CI_CONFIG_DIR}/${PARENT_TEMPLATE_DIR:-undefined}/github/config.yml" ]]; then
    cp -r "${CI_CONFIG_DIR}/${PARENT_TEMPLATE_DIR}/github/config.yml" ".github/ISSUE_TEMPLATE/"
  else
    cp -r "${CI_DIR}/shared/github/config.yml" ".github/ISSUE_TEMPLATE/"
  fi

  if [[ -f "${CI_DIR}/${PARENT_TEMPLATE_DIR:-undefined}/github/PULL_REQUEST_TEMPLATE.md" ]]; then
    cp -r "${CI_DIR}/${PARENT_TEMPLATE_DIR}/github/PULL_REQUEST_TEMPLATE.md" ".github"
  elif [[ -f "${CI_CONFIG_DIR}/${PARENT_TEMPLATE_DIR:-undefined}/github/PULL_REQUEST_TEMPLATE.md" ]]; then
    cp -r "${CI_CONFIG_DIR}/${PARENT_TEMPLATE_DIR}/github/PULL_REQUEST_TEMPLATE.md" ".github"
  else
    cp -r "${CI_DIR}/shared/github/PULL_REQUEST_TEMPLATE.md" ".github"
  fi

  if [[ -f "${CI_DIR}/${PARENT_TEMPLATE_DIR:-undefined}/github/${git_remote_name}/CONTRIBUTING.md" ]]; then
    cp -r "${CI_DIR}/${PARENT_TEMPLATE_DIR}/github/${git_remote_name}/CONTRIBUTING.md" ".github"
  elif [[ -f "${CI_DIR}/${PARENT_TEMPLATE_DIR:-undefined}/github/CONTRIBUTING.md" ]]; then
    cp -r "${CI_DIR}/${PARENT_TEMPLATE_DIR}/github/CONTRIBUTING.md" ".github"
  elif [[ -f "${CI_CONFIG_DIR}/${PARENT_TEMPLATE_DIR:-undefined}/github/${git_remote_name}/CONTRIBUTING.md" ]]; then
    cp -r "${CI_CONFIG_DIR}/${PARENT_TEMPLATE_DIR}/github/${git_remote_name}/CONTRIBUTING.md" ".github"
  elif [[ -f "${CI_CONFIG_DIR}/${PARENT_TEMPLATE_DIR:-undefined}/github/CONTRIBUTING.md" ]]; then
    cp -r "${CI_CONFIG_DIR}/${PARENT_TEMPLATE_DIR}/github/CONTRIBUTING.md" ".github"
  else
    cp -r "${CI_DIR}/shared/github/CONTRIBUTING.md" ".github"
    if [[ ! -f "scripts/create-docker-container.bash" ]]; then
      echo "Missing create-docker-container.bash as a required file in CONTRIBUTING.md"
      exit 1
    fi
    if [[ ! -f "scripts/test-in-docker.bash" ]]; then
      echo "Missing test-in-docker.bash as a required file in CONTRIBUTING.md"
      exit 1
    fi
  fi
  cat > ".github/TEMPLATE-README.md" << EOF

> [!IMPORTANT]
> Content in this directory is managed by the CI task \`sync-dot-github-dir\`.

Changing templates
---------------
These templates are synced from [these shared templates](https://github.com/cloudfoundry/wg-app-platform-runtime-ci/tree/main/shared/github).
Each pipeline will contain a \`sync-dot-github-dir-*\` job for updating the content of these files.
If you would like to modify these, please change them in the shared group.
It's also possible to override the templates on pipeline's parent directory by introducing a custom
template in \`\$PARENT_TEMPLATE_DIR/github/FILENAME\`  or \`\$PARENT_TEMPLATE_DIR/github/REPO_NAME/FILENAME\` in CI repo
EOF

  if [[ $(git status --porcelain) ]]; then
    git checkout -
    git add -A .
    git commit -m "Sync .github dir templates"
  fi

  rsync -a $PWD/ "$SYNCED_REPO_DIR"

  popd > /dev/null
}

trap 'err_reporter $LINENO' ERR
run "$@"
