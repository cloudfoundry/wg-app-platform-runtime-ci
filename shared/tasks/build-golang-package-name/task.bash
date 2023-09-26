#!/bin/bash
# fragile for loops on find
# shellcheck disable=SC2044

set -eEu
set -o pipefail

go_version_file=$PWD/ci/go_version.json

go_minor_version=$(cat ${go_version_file} | jq -r "if (.releases.\"${RELEASE}\" == null) then .default else .releases.\"${RELEASE}\" end")

cat <<HERE > $PWD/package-name/name
golang-${go_minor_version}-${PLATFORM}
HERE
