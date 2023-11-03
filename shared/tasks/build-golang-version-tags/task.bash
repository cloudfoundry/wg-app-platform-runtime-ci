#!/bin/bash
# fragile for loops on find
# shellcheck disable=SC2044 

set -eEu
set -o pipefail

get_latest_minor_version() {
  local minor_version=$1
  curl -s https://go.dev/dl/?mode=json | jq -r ".[].version | select(. | startswith(\"go${minor_version}\"))"
}

get_latest_image_go_version() {
  local image_name=$1

  go_version_file=$PWD/ci/go-version.json

  go_minor_version=$(cat ${go_version_file} | jq -r "if (.images.\"${image_name}\" == null) then .default else .images.\"${image_name}\" end")

  latest_minor_version="$(get_latest_minor_version ${go_minor_version})"

  echo "${latest_minor_version#go}"
}

get_latest_release_go_version() {
  local release_name=$1

  go_version_file=$PWD/ci/go-version.json

  go_minor_version=$(cat ${go_version_file} | jq -r "if (.releases.\"${release_name}\" == null) then .default else .releases.\"${release_name}\" end")

  latest_minor_version="$(get_latest_minor_version ${go_minor_version})"

  echo "${latest_minor_version#go}"
}

GO_VERSION="$(get_latest_image_go_version ${IMAGE})"
if [ -z "$GO_VERSION" ]; then
  echo "failed to find go version for image ${IMAGE}"
  exit 1
fi

cat <<HERE > $PWD/tag/tag
go-${GO_VERSION}
HERE
cat <<HERE > $PWD/tag/version
go-${GO_VERSION}
HERE
cat <<HERE > $PWD/tag/build-args
{ "go_version": "${GO_VERSION}" }
HERE
