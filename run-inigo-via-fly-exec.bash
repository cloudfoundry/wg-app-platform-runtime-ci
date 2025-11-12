#!/bin/bash

set -euo pipefail

GARDEN_RELEASE=${GARDEN_RELEASE:-${HOME}/workspace/garden-runc-release}
DIEGO_RELEASE=${DIEGO_RELEASE:-${HOME}/workspace/diego-release}
ROUTING_RELEASE=${ROUTING_RELEASE:-${HOME}/workspace/routing-release}

export FLY_TARGET=wg-arp-diego
export DIR=src/code.cloudfoundry.org/inigo

OUTPUT_CACHE_DIR=${OUTPUT_CACHE_DIR:-$(mktemp -d)}

trap 'echo "Set OUTPUT_CACHE_DIR=$OUTPUT_CACHE_DIR to re-use build steps that have completed successfully"' exit


if [[ ! -d ${OUTPUT_CACHE_DIR}/diego_built_binaries ]]; then
    DEFAULT_PARAMS=ci/diego-release/default-params/build-binaries/linux.yml ./bin/fly-exec.bash build-binaries -i repo="${DIEGO_RELEASE}" -o built-binaries="${OUTPUT_CACHE_DIR}/diego_built_binaries"
fi

if [[ ! -d ${OUTPUT_CACHE_DIR}/garden_built_binaries ]]; then
    DEFAULT_PARAMS=ci/garden-runc-release/default-params/build-binaries/linux.yml ./bin/fly-exec.bash build-binaries -i repo="${GARDEN_RELEASE}" -o built-binaries="${OUTPUT_CACHE_DIR}/garden_built_binaries"
fi

if [[ ! -d ${OUTPUT_CACHE_DIR}/built_binaries ]]; then
    export COPY_ACTIONS="
        {input-01/*,combined-assets}
        {input-02/*,combined-assets}"
    ./bin/fly-exec.bash combine-assets -i input-01="${OUTPUT_CACHE_DIR}/diego_built_binaries" -i input-02="${OUTPUT_CACHE_DIR}/garden_built_binaries" -o combined-assets="${OUTPUT_CACHE_DIR}/built_binaries"
fi

if [[ ! -d ${OUTPUT_CACHE_DIR}/diego-inigo-ci-rootfs ]]; then
    docker pull cloudfoundry/diego-inigo-ci-rootfs
    mkdir -p "${OUTPUT_CACHE_DIR}/diego-inigo-ci-rootfs"
    docker save cloudfoundry/diego-inigo-ci-rootfs > "${OUTPUT_CACHE_DIR}/diego-inigo-ci-rootfs/rootfs.tar" 
fi

export ENVS="
          INIGO_ECR_AWS_ACCESS_KEY_ID=((aws-ecr-diego-docker-app/access-key-id))
          INIGO_ECR_AWS_SECRET_ACCESS_KEY=((aws-ecr-diego-docker-app/secret-access-key))
          INIGO_ECR_IMAGE_REF=((aws-ecr-diego-docker-app/ref))
          INIGO_ECR_IMAGE_ROOTFS_PATH=((aws-ecr-diego-docker-app/uri))
          INIGO_ECR_IMAGE_URI=((aws-ecr-diego-docker-app/uri))
          ROUTING_RELEASE_PATH=$PWD/input-01
          GARDEN_RUNC_RELEASE_PATH=$PWD/input-02
          DIEGO_RELEASE_PATH=$PWD/repo
          GARDEN_TEST_ROOTFS=$PWD/input-03/rootfs.tar
          DB_USER=root
          DB_PASSWORD=password"

export FLAGS="
          --keep-going
          --trace
          -r
          --fail-on-pending
          --randomize-all
          --nodes=4
          --race
          --flake-attempts=3
          ${*}
"
IMAGE=cloudfoundry/tas-runtime-mysql ./bin/fly-exec.bash run-bin-test -i repo="$DIEGO_RELEASE" -i built-binaries="${OUTPUT_CACHE_DIR}/built_binaries" -i input-01="$ROUTING_RELEASE" input-02="$GARDEN_RELEASE" -i input-03="${OUTPUT_CACHE_DIR}/diego-inigo-ci-rootfs"
