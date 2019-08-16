#!/usr/bin/env bash

set -ex

fly -t ${DIEGO_CI_TARGET:-ci} sp -p main -c diego-pipeline.yml --load-vars-from <(lpass show --notes "diego-pipeline-secrets")
