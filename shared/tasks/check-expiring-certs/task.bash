#!/bin/bash

set -eu
set -o pipefail

echo "Checking for expired certs"

expired_certs=$(find /repo -name *.crt | xargs -I{} /ci/shared/tasks/check-expiring-certs/check.rb {} 60)
if [ ! -z "$expired_certs" ]; then
  echo "Found certs expiring in 60 days:"
  echo "$expired_certs"
  exit 1
fi
