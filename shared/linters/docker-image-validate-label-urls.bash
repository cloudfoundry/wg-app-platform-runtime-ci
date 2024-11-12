#!/bin/bash

set -eu
set -o pipefail

function run() {
  local docker_image_path=${1:?Provide a path to the docker-image}
  if [ -f "$docker_image_path/docker_inspect.json" ]; then
    cat "$docker_image_path/docker_inspect.json" | jq -r '.[].Config.Labels | with_entries(if (.key|test("org.cloudfoundry.*.*.url$")) then ( {key: .key, value: .value } ) else empty end ) | .[]' | xargs -I {} sh -c 'printf "{} -> " && curl --fail -o /dev/null -s -w "%{http_code}\n" {} '
  else
    cat "$docker_image_path/labels.json" | jq -r '. | with_entries(if (.key|test("org.cloudfoundry.*.*.url$")) then ( {key: .key, value: .value } ) else empty end ) | .[]' | xargs -I {} sh -c 'printf "{} -> " && curl --fail -o /dev/null -s -w "%{http_code}\n" {} '
  fi
}

run "$@"
