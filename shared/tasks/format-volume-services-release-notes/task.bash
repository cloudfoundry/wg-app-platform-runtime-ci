#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$PWD
export RELEASE_NOTES_PATH="$ROOT_DIR/raw-release-notes/release-notes.json"
export RELEASE_NOTES_DIR="$ROOT_DIR/raw-release-notes/"

erb -T- ci/shared/tasks/format-volume-services-release-notes/release-notes-auto.md.erb > release-notes/release-notes.md

echo -e "\n > Generated Release Notes:"
cat release-notes/release-notes.md
