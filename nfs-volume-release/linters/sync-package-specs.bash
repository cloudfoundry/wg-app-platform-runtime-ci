#!/bin/bash

set -eu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../shared/helpers/git-helpers.bash"
unset THIS_FILE_DIR

function run() {
  local repo_path=${1:?Provide a path to the repository}
  local exit_on_error=${2:-"false"}

  pushd "${repo_path}" > /dev/null

  sync_package nfsbroker nfsbroker \
    -app . &

  sync_package nfsv3driver nfsv3driver \
    -app code.cloudfoundry.org/nfsv3driver/cmd/nfsv3driver &

  sync_package dockerdriver-integration dockerdriver \
    -app github.com/onsi/ginkgo/v2/ginkgo \
    -test code.cloudfoundry.org/dockerdriver/integration/... &

  sync_package map-fs-performance-acceptance-tests mapfs-performance-acceptance-tests \
    -app github.com/onsi/ginkgo/v2/ginkgo \
    -test code.cloudfoundry.org/mapfs-performance-acceptance-tests/... &

  wait

  git diff --name-only packages/*/spec

  if [[ "$exit_on_error" == "true" ]]; then
    git_error_when_diff
  fi

  popd > /dev/null
}

function sync_package() {
  bosh_pkg=${1}
  src_dir=${2}

  shift
  shift

  (
  set -e

  cd "src/code.cloudfoundry.org/${src_dir}"

  spec=../../../packages/${bosh_pkg}/spec

  {
    cat $spec | grep -v '# gosub'

    for package in $(gosub list "$@"); do
      repo=$(echo ${2} | cut -f1-3 -d/)
      base_pkg="$(echo $package | cut -f2- -d /)"
      if [ -d "../../../src/code.cloudfoundry.org/${src_dir}/vendor/${package}" ]; then
        package="code.cloudfoundry.org/${src_dir}/vendor/${package}"
      fi
      echo ${package} | sed -e 's/\(.*\)/  - \1\/*.go # gosub/g'
      if ls ../../${package}/*.s >/dev/null 2>&1; then
        echo ${package} | sed -e 's/\(.*\)/  - \1\/*.s # gosub/g'
      fi
      if ls ../../${package}/*.binpb >/dev/null 2>&1; then
        echo ${package} | sed -e 's/\(.*\)/  - \1\/*.binpb # gosub/g'
      fi
    done
  } > $spec.new

  mv $spec.new $spec
)
}

verify_binary gosub
run "$@"
