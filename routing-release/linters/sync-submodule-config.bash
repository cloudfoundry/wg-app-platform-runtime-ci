#!/bin/bash

set -eu
set -o pipefail

function run() {
  pushd "${REPO_PATH}" > /dev/null

  rm -rf /tmp/packages
  cat > /tmp/packages <<EOF
code.cloudfoundry.org/cf-routing-test-helpers
code.cloudfoundry.org/cf-tcp-router
code.cloudfoundry.org/gorouter
code.cloudfoundry.org/multierror
code.cloudfoundry.org/route-registrar
code.cloudfoundry.org/routing-acceptance-tests
code.cloudfoundry.org/routing-api
code.cloudfoundry.org/routing-api-cli
code.cloudfoundry.org/routing-info
gosub
EOF

cat /tmp/packages | xargs -s 1048576 gosub sync --force-https=true

popd > /dev/null
}


if [[ "${1:-empty}" != "empty" ]]; then
  export REPO_PATH="${1}"
  shift 1
else
  export REPO_PATH=${REPO_PATH}
fi

export PATH="${REPO_PATH}/tmp:$PATH"

(
mkdir -p ${REPO_PATH}/tmp
go build -C "${REPO_PATH}/src/gosub" -o "${REPO_PATH}/tmp/gosub" .
)

run "$@"
