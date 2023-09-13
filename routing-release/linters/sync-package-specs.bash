#!/bin/bash

set -eu
set -o pipefail

function run() {
    pushd "${REPO_PATH}" > /dev/null

    sync_package tcp_router        -app code.cloudfoundry.org/cf-tcp-router/... &
    sync_package routing-api       -app code.cloudfoundry.org/routing-api/cmd/... &
    sync_package rtr               -app code.cloudfoundry.org/routing-api-cli/... &
    sync_package gorouter          -app code.cloudfoundry.org/gorouter/... &
    sync_package route_registrar   -app code.cloudfoundry.org/route-registrar/... &
    sync_package acceptance_tests \
      -test code.cloudfoundry.org/routing-acceptance-tests/... \
      -app github.com/onsi/ginkgo/v2/ginkgo &

    wait

    git diff --name-only packages/*/spec

    if ! git diff-files --exit-code --ignore-submodules; then
    echo >&2 "There are unstaged changes in the index!"
    exit 1
    fi

    if ! git diff-index --cached --exit-code HEAD --ignore-submodules; then
    echo >&2 "There are uncommitted changes in the index!"
    exit 1
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
      done
    } > $spec.new

    mv $spec.new $spec
  )
}

if [[ "${1:-empty}" != "empty" ]]; then
  export REPO_PATH="${1}"
  shift 1
else
  export REPO_PATH=${REPO_PATH}
fi

export PATH="${REPO_PATH}/tmp:$PATH"

(
  mkdir -p ${REPO_PATH}/tmp
  go build -C "${REPO_PATH}/src/gosub" -o "${REPO_PATH}/tmp/gosub" .
)

run "$@"
