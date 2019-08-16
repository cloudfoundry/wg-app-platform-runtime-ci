#!/usr/bin/env bash

set -ex

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
lpass status 2>&1 > /dev/null;
if [[ $? -eq 0 ]]; then
  fly -t ${DIEGO_CI_TARGET:-ci} sp -p docker-images -c $DIR/../pipelines/docker-pipeline.yml --load-vars-from <(lpass show --notes "diego-pipeline-secrets")
else
  echo "Login to lastpass: 'lpass login ...'";
fi
