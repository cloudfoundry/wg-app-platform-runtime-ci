#!/bin/bash

set -eu
set -o pipefail

function run() {
  local task_tmp_dir="${1:?provide temp dir for task}"
  shift 1
  local repo_path=${1:?Provide a path to the repository}

  pushd "${repo_path}" > /dev/null
  install_protoc "$task_tmp_dir"

  pushd src/code.cloudfoundry.org > /dev/null
  go generate -run generate_proto ./...
  git diff --exit-code
  popd > /dev/null

  popd > /dev/null
}

install_protoc() {
  local tmpDir="${1:?Provide a dir path}"
  pushd "$tmpDir"
  local protobuf_version=$(curl -s https://api.github.com/repos/protocolbuffers/protobuf/releases | jq -r '.[].tag_name as $tags | $tags | select(. | contains("-rc") | not) | [.]' | jq -sr 'sort | reverse | add | .[0]')
  echo "protoc version: ${protobuf_version}"
  local url=$(curl -s https://api.github.com/repos/protocolbuffers/protobuf/releases | jq --arg pbv "${protobuf_version}" -r '.[] | select(.tag_name == $pbv) | .assets[] | select(.name | contains("linux-x86_64")).browser_download_url')
  curl -L "${url}" -o protoc-zip
  unzip -o protoc-zip -d protoc/
  export PATH=$PATH:$PWD/protoc/bin/
  popd

  go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
  go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
  pushd "${repo_path}/src/code.cloudfoundry.org/bbs/protoc-gen-go-bbs" > /dev/null
    go install .
  popd
}

function cleanup() {
    rm -rf $task_tmp_dir
}

task_tmp_dir="$(mktemp -d -t 'XXXX-linter-tmp-dir')"
trap cleanup EXIT
run $task_tmp_dir "$@"
