#!/bin/bash

function run() {
  local repo_path=${1:?Provide a path to the repository}

  containerd_version=$(cat ${repo_path}/src/guardian/go.sum | grep github.com/containerd/containerd/v2 | cut -d' ' -f2 | head -n 1)

  pushd "${repo_path}" > /dev/null
  pushd src/containerd > /dev/null
  echo "Checking out ${containerd_version} containerd"
  git checkout $containerd_version
  popd > /dev/null
  popd > /dev/null
}

run "$@"
