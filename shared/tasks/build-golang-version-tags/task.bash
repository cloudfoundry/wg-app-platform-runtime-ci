#!/bin/bash
# fragile for loops on find
# shellcheck disable=SC2044 

set -eEu
set -o pipefail
set -x

get_latest_minor_version() {
  local minor_version="$1"
  patch_version="$(curl -s https://go.dev/dl/?mode=json | jq -r ".[].version | select(. | startswith(\"go${minor_version}\"))")"
  echo "${patch_version#go}"
}

GO_VERSION="$(get_latest_minor_version "${GO_MAJOR_MINOR_VERSION}")"
if [ -z "$GO_VERSION" ]; then
  echo "failed to find go version for image ${IMAGE}"
  exit 1
fi

echo "Latest version for ${GO_MAJOR_MINOR_VERSION} is ${GO_VERSION}"

cat <<HERE > $PWD/tag/tag
go-${GO_VERSION}
HERE
cat <<HERE > $PWD/tag/version
go-${GO_VERSION}
HERE
cat <<HERE > $PWD/tag/build-args
{ "go_version": "${GO_VERSION}" }
HERE
