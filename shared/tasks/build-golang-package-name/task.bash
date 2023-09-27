#!/bin/bash
# fragile for loops on find
# shellcheck disable=SC2044

set -eEu
set -o pipefail

go_version_file=$PWD/ci/go_version.json

go_minor_version=$(cat ${go_version_file} | jq -r "if (.releases.\"${RELEASE}\" == null) then .default else .releases.\"${RELEASE}\" end")
package_name=$(if [[ -n $PREFIX ]]; then echo "$PREFIX-golang-${go_minor_version}-${PLATFORM}"; else echo "golang-${go_minor_version}-${PLATFORM}"; fi)

cat <<HERE > $PWD/package-name/name
${package_name}
HERE

old_package_glob=$(if [[ -n $PREFIX ]]; then echo "$PREFIX-golang-*-${PLATFORM}"; else echo "golang-*-${PLATFORM}"; fi)

old_package_name=$(find repo/packages -name "${old_package_glob}" -printf '%f')
cat <<HERE > $PWD/package-name/old-name
${old_package_name}
HERE
