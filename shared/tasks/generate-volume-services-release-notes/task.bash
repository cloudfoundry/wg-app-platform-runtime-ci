#!/usr/bin/env bash

set -eu

ROOT_DIR=$PWD
REPO_DIR="$ROOT_DIR/repo"

pushd "$REPO_DIR"
  export FROM_TAG=$(git describe --abbrev=0 --tags)
popd

pushd ci/shared/assets/generate-volume-services-release-notes
  make init > /dev/null

  python main.py

  cp release-notes.json "$ROOT_DIR/raw-release-notes/release-notes.json"
popd

