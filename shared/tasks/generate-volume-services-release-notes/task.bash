#!/usr/bin/env bash

set -eu

ROOT_DIR=$PWD
REPO_DIR="$ROOT_DIR/repo"

pushd "$REPO_DIR"
  export FROM_TAG=$(git describe --abbrev=0 --tags)
popd

pushd cryogenics-concourse-tasks/tasks/release-automation/release-notes/src
  make init > /dev/null

  python main.py

  cp release-notes.json "$ROOT_DIR/raw-release-notes/release-notes.json"
popd

