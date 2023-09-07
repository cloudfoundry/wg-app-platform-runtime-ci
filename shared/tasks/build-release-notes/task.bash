#!/bin/bash

set -eEu
set -o pipefail


THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename "$THIS_FILE_DIR")"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"
unset THIS_FILE_DIR

function run(){
  git_safe_directory

  pushd repo > /dev/null
  commit_message=$(git log -1 --oneline --grep="Upgrade golang-" packages/golang-*)
  go_version=$(echo "${commit_message}" | sed -En 's/.*Upgrade golang-.* \((.*)\)/\1/p')
  if [[ -z ${go_version} ]]; then
    echo "Could not detect go version from git history of 'packages/golang-*':"
    echo "${commit_message}"
    exit 1
  fi

  local release_name="$(get_git_remote_name)"

  local spec_diff=$(get_bosh_job_spec_diff)
  popd > /dev/null

  local new_version="$(cat version/number)"
  local old_version="$(cat previous-github-release/tag)"

  cat >> built-release-notes/notes.md <<EOF
## Changes

- FIXME: enter release notes here

${spec_diff}

## ✨  Built with go ${go_version}

**Full Changelog**: https://github.com/cloudfoundry/${release_name}/compare/${old_version}...${new_version}

## Resources

- [Download release ${new_version} from bosh.io](https://bosh.io/releases/github.com/cloudfoundry/${release_name}?version=${new_version}).
EOF


echo "Results: "
cat built-release-notes/notes.md
}

function get_bosh_job_spec_diff(){
  if ls jobs/*/spec 1> /dev/null 2>&1; then
    local repo_head_version=$(git rev-parse HEAD)
    local repo_released_version=$(git tag --sort=version:refname | grep -E "^v?[0-9]+\.[0-9]+\.[0-9]+$" | tail -1)

    local diff_string="${repo_released_version}..${repo_head_version}"
    debug "comparing ${diff_string}:"
    local job_spec_diff="$(git --no-pager diff "${diff_string}" jobs/*/spec)"

    if [[ -n "${job_spec_diff}" ]]; then
      debug "Job spec diff: ${job_spec_diff}"
      cat <<EOF
## Bosh Job Spec changes:

\`\`\`diff
${job_spec_diff}

\`\`\`
EOF
    fi
  fi
}

trap 'err_reporter $LINENO' ERR
run "$@"
