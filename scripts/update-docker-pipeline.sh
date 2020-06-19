#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FLY_EXE=$(which fly)
if type -p "fly-diego-ci" > /dev/null; then
  FLY_EXE=$(which fly-diego-ci)
fi
lpass status 2>&1 > /dev/null;
if [[ $? -eq 0 ]]; then
  "$FLY_EXE" -t ${DIEGO_CI_TARGET:-ci} sp -p temp-docker-images-go1.13.12 -c $DIR/../pipelines/docker-pipeline.yml --load-vars-from <(lpass show --notes "diego-pipeline-secrets") "$@"
else
  echo "Login to lastpass: 'lpass login ...'";
fi
