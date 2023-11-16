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

  BUILD_FLAGS="--tags cgo,no_btrfs" sync_package containerd guardian \
    -app github.com/containerd/containerd/cmd/ctr \
    -app github.com/containerd/containerd/cmd/containerd \
    -app github.com/containerd/containerd/cmd/containerd-shim \
    -app github.com/containerd/containerd/cmd/containerd-shim-runc-v1 \
    -app github.com/containerd/containerd/cmd/containerd-shim-runc-v2 &

  BUILD_FLAGS="--tags cgo,seccomp,apparmor" sync_package runc guardian \
    -app github.com/opencontainers/runc &

  BUILD_FLAGS="--tags cloudfoundry" sync_package grootfs grootfs \
    -app code.cloudfoundry.org/grootfs \
    -app code.cloudfoundry.org/grootfs/store/filesystems/overlayxfs/tardis &

  sync_package gats garden-integration-tests -app github.com/onsi/ginkgo/v2/ginkgo \
    -test code.cloudfoundry.org/garden-integration-tests/... \
    -app code.cloudfoundry.org/garden-integration-tests/plugins/consume-mem &

  sync_package gpats garden-performance-acceptance-tests -app  github.com/onsi/ginkgo/v2/ginkgo \
    -test code.cloudfoundry.org/garden-performance-acceptance-tests/... &

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

  cd "src/${src_dir}"

  spec=../../packages/${bosh_pkg}/spec

  {
    cat $spec | grep -v '# gosub'

    for package in $("$RELEASE_DIR/bin/gosub" list "$@"); do
      repo=$(echo ${2} | cut -f1-3 -d/)
      base_pkg="$(echo $package | cut -f2- -d /)"
      if [ -d "../../src/${src_dir}/vendor/${package}" ]; then
        package="${src_dir}/vendor/${package}"
      else
        package="${base_pkg}"
      fi
      echo ${package} | sed -e 's/\(.*\)/  - \1\/*.go # gosub/g'
      if ls ../../src/${package}/*.s >/dev/null 2>&1; then
        echo ${package} | sed -e 's/\(.*\)/  - \1\/*.s # gosub/g'
      fi
      if ls ../../src/${package}/*.h >/dev/null 2>&1; then
        echo ${package} | sed -e 's/\(.*\)/  - \1\/*.h # gosub/g'
      fi
      if ls ../../src/${package}/*.c >/dev/null 2>&1; then
        echo ${package} | sed -e 's/\(.*\)/  - \1\/*.c # gosub/g'
      fi
      if ls ../../src/${package}/Makefile >/dev/null 2>&1; then
        echo ${package} | sed -e 's/\(.*\)/  - \1\/Makefile # gosub/g'
      fi
    done
  } > $spec.new

  mv $spec.new $spec
)
}


verify_binary gosub
run "$@"
