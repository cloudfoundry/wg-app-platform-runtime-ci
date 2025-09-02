#!/bin/bash

set -eEu
set -o pipefail


THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename "$THIS_FILE_DIR")"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/git-helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"
unset THIS_FILE_DIR

function run(){
  git_configure_safe_directory

  local released_binaries_path="$PWD/released-binaries"

  local new_version
  new_version="$(cat version/number)"
  local old_version
  old_version="$(cat previous-github-release/tag)"

  # Compensate for previous github tag having a `v` prefix
  local new_tag_version="${new_version}"
  if [[ "${old_version}" =~ ^v ]]; then
    new_tag_version="v${new_version}"
  fi

  pushd repo > /dev/null
  local go_version repo_name spec_diff
  if [[ "$(is_repo_bosh_release)" == "yes" ]]; then
    go_version=$(get_go_version_for_release "$PWD" "golang-*linux")
    if [[ -z "${go_version}" ]]; then
      go_version=$(get_go_version_for_release "$PWD" "golang-*windows")
    fi
  else
    if [[ -d "${released_binaries_path}" ]]; then
      go_version=$(get_go_version_for_binaries "${released_binaries_path}")
    else 
      echo "Missing released-binaries dir for repo that's not a bosh-release"
      exit 1
    fi
  fi

  local built_with_go=""
  if [[ -n "${go_version}" ]]; then
    built_with_go="## ✨  Built with go ${go_version}"
  fi

  repo_name="$(git_get_remote_name)"
  spec_diff=$(get_bosh_job_spec_diff)
  local bosh_io_resources

  if [[ ${BOSH_IO_ORG:-skip} != "skip" ]]; then
    bosh_io_resources="$(get_bosh_io_resources "${BOSH_IO_ORG}" "${repo_name}" "${new_version}")"
  fi
  popd > /dev/null

  local extra_metadata
  if [[ -d extra-metadata ]] && [[ $(compgen -G extra-metadata/*) ]]; then
    extra_metadata=$(cat extra-metadata/*)
  fi

  local dashed_version
  dashed_version="$(echo ${new_version} | sed  s/\\./-/g)"

  cat >> built-release-notes/notes.md <<EOF
## <a id="${dashed_version}"></a> ${new_version}

**Release Date**: $(date  +"%B %d, %Y")

## Changes

- FIXME: enter release notes here

${spec_diff}
${built_with_go}

**Full Changelog**: ${GITHUB_ORG_URL}/${repo_name}/compare/${old_version}...${new_tag_version}

${bosh_io_resources:-}
${extra_metadata:-}
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

function get_bosh_io_resources() {
  local bosh_io_org=$1
  local bosh_io_repo=$2
  local version=$3

  if ls jobs/*/spec 1> /dev/null 2>&1; then
    cat <<EOF
## Resources

- [Download release ${version} from bosh.io](https://bosh.io/releases/github.com/${bosh_io_org}/${bosh_io_repo}?version=${version}).
EOF
  fi
}

trap 'err_reporter $LINENO' ERR
run "$@"
