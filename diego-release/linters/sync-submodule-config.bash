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
code.cloudfoundry.org/auction
code.cloudfoundry.org/auctioneer
code.cloudfoundry.org/bbs
code.cloudfoundry.org/buildpackapplifecycle
code.cloudfoundry.org/cacheddownloader
code.cloudfoundry.org/cfdot
code.cloudfoundry.org/credhub-cli
code.cloudfoundry.org/diego-ssh
code.cloudfoundry.org/dockerapplifecycle
code.cloudfoundry.org/ecrhelper
code.cloudfoundry.org/executor
code.cloudfoundry.org/fileserver
code.cloudfoundry.org/healthcheck
code.cloudfoundry.org/inigo
code.cloudfoundry.org/localdriver
code.cloudfoundry.org/locket
code.cloudfoundry.org/operationq
code.cloudfoundry.org/rep
code.cloudfoundry.org/route-emitter
code.cloudfoundry.org/routing-api
code.cloudfoundry.org/routing-info
code.cloudfoundry.org/vendor
code.cloudfoundry.org/vizzini
code.cloudfoundry.org/volman
code.cloudfoundry.org/workpool
garden
grootfs
guardian
idmapper
cnbapplifecycle
EOF

cat /tmp/packages | xargs -s 1048576 gosub sync --force-https=true

if [[ "$exit_on_error" == "true" ]]; then
  git_error_when_diff
fi

popd > /dev/null

}

verify_binary gosub
run "$@"
