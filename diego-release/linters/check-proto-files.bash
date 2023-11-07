#!/bin/bash

set -eu
set -o pipefail

function run() {
  local task_tmp_dir="${1:?provide temp dir for task}"
  shift 1
  local repo_path=${1:?Provide a path to the repository}

  pushd "${repo_path}" > /dev/null
  install_protoc "$task_tmp_dir"
  install_gogoslick "$task_tmp_dir"

  pushd src/code.cloudfoundry.org > /dev/null
  go generate -run generate_proto ./...
  git diff --exit-code
  popd > /dev/null

  exit 1

  popd > /dev/null
}

install_protoc() {
  local tmpDir="${1:?Provide a dir path}"
  pushd "$tmpDir"
  wget "https://github.com/protocolbuffers/protobuf/releases/download/v3.10.1/protoc-3.10.1-linux-x86_64.zip"
  unzip -o "protoc-3.10.1-linux-x86_64.zip" -d protoc/
  export PATH=$PATH:$PWD/protoc/bin/
  popd

}

install_gogoslick() {
  local tmpDir="${1:?Provide a dir path}"
  mkdir -p "$tmpDir/bin"
  pushd "$PWD/src/code.cloudfoundry.org" > /dev/null
  go build -o "$tmpDir/bin/protoc-gen-gogoslick" github.com/gogo/protobuf/protoc-gen-gogoslick
  popd > /dev/null
  export PATH="$PATH:$tmpDir/bin"
}

function cleanup() {
    rm -rf $task_tmp_dir
}

task_tmp_dir="$(mktemp -d -t 'XXXX-linter-tmp-dir')"
trap cleanup EXIT
run $task_tmp_dir "$@"
