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

  sync_package auctioneer              -app  code.cloudfoundry.org/auctioneer/cmd/auctioneer &
  sync_package bbs                     -app  code.cloudfoundry.org/bbs/cmd/bbs &
  sync_package cfdot                   -app  code.cloudfoundry.org/cfdot &
  sync_package diego-sshd              -app  code.cloudfoundry.org/diego-ssh/cmd/sshd &
  sync_package file_server             -app  code.cloudfoundry.org/fileserver/cmd/file-server &
  sync_package locket                  -app  code.cloudfoundry.org/locket/cmd/locket &
  sync_package rep                     -app  code.cloudfoundry.org/rep/cmd/rep -app  code.cloudfoundry.org/rep/cmd/gocurl &
  sync_package rep_windows             -app  code.cloudfoundry.org/rep/cmd/rep -app  code.cloudfoundry.org/rep/cmd/gocurl &
  sync_package route_emitter           -app  code.cloudfoundry.org/route-emitter/cmd/route-emitter &
  sync_package route_emitter_windows   -app  code.cloudfoundry.org/route-emitter/cmd/route-emitter &
  sync_package ssh_proxy               -app  code.cloudfoundry.org/diego-ssh/cmd/ssh-proxy &
  sync_package certsplitter            -app  code.cloudfoundry.org/certsplitter/cmd/certsplitter &

  sync_package docker_app_lifecycle    -app  code.cloudfoundry.org/dockerapplifecycle/builder \
    -app code.cloudfoundry.org/dockerapplifecycle/launcher &

  sync_package cnb_app_lifecycle       -app  code.cloudfoundry.org/cnbapplifecycle/cmd/builder \
    -app code.cloudfoundry.org/cnbapplifecycle/cmd/launcher &

  sync_package buildpack_app_lifecycle -app  code.cloudfoundry.org/buildpackapplifecycle/builder \
    -app code.cloudfoundry.org/buildpackapplifecycle/launcher \
    -app code.cloudfoundry.org/buildpackapplifecycle/getenv \
    -app code.cloudfoundry.org/buildpackapplifecycle/shell/shell &

  sync_package windows_app_lifecycle -app  code.cloudfoundry.org/buildpackapplifecycle/builder \
    -app code.cloudfoundry.org/buildpackapplifecycle/launcher \
    -app code.cloudfoundry.org/buildpackapplifecycle/getenv &

  sync_package vizzini \
    -app  github.com/onsi/ginkgo/v2/ginkgo \
    -test code.cloudfoundry.org/vizzini/... &

  wait

  git diff --name-only packages/*/spec

  if [[ "$exit_on_error" == "true" ]]; then
    git_error_when_diff
  fi

  popd > /dev/null
}

function sync_package() {
  bosh_pkg=${1}

  shift

  (
  set -e

  cd src/code.cloudfoundry.org

  spec=../../packages/${bosh_pkg}/spec

  {
    cat $spec | grep -v '# gosub'

    for package in $(gosub list "$@"); do
      repo=$(echo ${2} | cut -f1-3 -d/)
      if [ -d "../../src/code.cloudfoundry.org/vendor/${package}" ]; then
        package="code.cloudfoundry.org/vendor/${package}"
      fi
      echo ${package} | sed -e 's/\(.*\)/  - \1\/*.go # gosub/g'
      if ls ../../src/${package}/*.s >/dev/null 2>&1; then
        echo ${package} | sed -e 's/\(.*\)/  - \1\/*.s # gosub/g'
      fi
      if ls ../../src/${package}/*.h >/dev/null 2>&1; then
        echo ${package} | sed -e 's/\(.*\)/  - \1\/*.h # gosub/g'
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
