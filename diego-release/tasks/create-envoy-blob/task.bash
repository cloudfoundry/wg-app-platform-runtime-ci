#!/bin/bash

set -e -x

BASE_DIR=$PWD

ENVOY_TAG=$(cat envoy-release/tag)

# Fetch envoy
pushd /tmp

wget https://raw.githubusercontent.com/envoyproxy/envoy/refs/tags/"${ENVOY_TAG}"/LICENSE
wget https://raw.githubusercontent.com/envoyproxy/envoy/refs/tags/"${ENVOY_TAG}"/NOTICE
wget https://github.com/envoyproxy/envoy/releases/download/"${ENVOY_TAG}"/envoy-"${ENVOY_TAG:1}"-linux-x86_64 -O envoy

popd

cp "/tmp/envoy" "${BASE_DIR}/envoy-binary/envoy"
cp "/tmp/LICENSE" "${BASE_DIR}/envoy-binary/LICENSE"
cp "/tmp/NOTICE" "${BASE_DIR}/envoy-binary/NOTICE"

pushd envoy-binary
  chmod 755 envoy
  tar -czf envoy.tgz envoy LICENSE NOTICE
popd
