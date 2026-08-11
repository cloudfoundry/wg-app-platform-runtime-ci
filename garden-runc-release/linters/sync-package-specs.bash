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

  BUILD_FLAGS="--tags cgo,seccomp" sync_package runc \
    -app github.com/opencontainers/runc &

  BUILD_FLAGS="--tags daemon" sync_package guardian \
    -app code.cloudfoundry.org/guardian/cmd/gdn \
    -app code.cloudfoundry.org/guardian/cmd/dadoo \
    -app code.cloudfoundry.org/guardian/cmd/socket2me \
    -app code.cloudfoundry.org/guardian/cmd/execas &

  BUILD_FLAGS="--tags cloudfoundry" sync_package grootfs \
    -app code.cloudfoundry.org/guardian/grootfs \
    -app code.cloudfoundry.org/guardian/idmapper \
    -app code.cloudfoundry.org/guardian/grootfs/store/filesystems/overlayxfs/tardis &

  BUILD_FLAGS="--tags windows" sync_package guardian-windows \
    -app code.cloudfoundry.org/guardian/cmd/gdn \
    -app code.cloudfoundry.org/guardian/cmd/winit &

  sync_package thresholder \
    -app code.cloudfoundry.org/thresholder &

  sync_package dontpanic \
    -app code.cloudfoundry.org/dontpanic &

  sync_package garden-idmapper \
    -app code.cloudfoundry.org/guardian/idmapper/cmd/newuidmap \
    -app code.cloudfoundry.org/guardian/idmapper/cmd/newgidmap \
    -app code.cloudfoundry.org/guardian/idmapper/cmd/maximus &

  sync_package greenskeeper \
    -app code.cloudfoundry.org/greenskeeper/cmd/greenskeeper &

  sync_package gats \
    -app github.com/onsi/ginkgo/v2/ginkgo \
    -test code.cloudfoundry.org/garden-integration-tests/... \
    -app code.cloudfoundry.org/garden-integration-tests/plugins/consume-mem &

  sync_package gpats \
    -app github.com/onsi/ginkgo/v2/ginkgo \
    -test code.cloudfoundry.org/garden-performance-acceptance-tests/... &

  wait

  git diff --name-only packages/*/spec

  if [[ "$exit_on_error" == "true" ]]; then
    git_error_when_diff
  fi

  popd > /dev/null
}

function sync_package() {
  local bosh_pkg=${1}
  shift

  (
  set -e

  cd "src/code.cloudfoundry.org"

  spec=../../packages/${bosh_pkg}/spec

  {
    cat $spec | grep -v '# gosub'

    for package in $(gosub list "$@"); do
      base_pkg="$(echo $package | cut -f2- -d /)"
      if [ -d "../../src/code.cloudfoundry.org/vendor/${package}" ]; then
        package="code.cloudfoundry.org/vendor/${package}"
      elif [ -d "../../src/code.cloudfoundry.org/${base_pkg}" ]; then
        package="code.cloudfoundry.org/${base_pkg}"
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
      if ls ../../src/${package}/*.binpb >/dev/null 2>&1; then
        echo ${package} | sed -e 's/\(.*\)/  - \1\/*.binpb # gosub/g'
      fi
    done
  } > $spec.new

  mv $spec.new $spec
)
}


verify_binary gosub
run "$@"
