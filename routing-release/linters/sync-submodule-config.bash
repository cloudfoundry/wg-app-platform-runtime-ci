#!/bin/bash

set -eu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../shared/helpers/git-helpers.bash"
unset THIS_FILE_DIR

function run() {
  local repo_path=${1:?Provide a path to the repository}
  local exit_on_error=${2:-"false"}
  pushd "${repo_path}" > /dev/null

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
EOF

cat /tmp/packages | xargs -s 1048576 gosub sync --force-https=true

if [[ "$exit_on_error" == "true" ]]; then
  git_error_when_diff
fi

popd > /dev/null

}

verify_binary gosub
run "$@"
