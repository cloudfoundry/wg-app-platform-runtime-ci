#!/bin/bash

set -e -x

DOCKERFILE="${DOCKERFILE_PATH%/Dockerfile}/Dockerfile"

if [[ ! -f "${DOCKERFILE}" ]]; then
  echo "Error: ${DOCKERFILE} was not found" >&2
  exit 1
fi

oras_tarball=(oras-cli/*_linux_amd64.tar.gz)
if [[ ! -f "${oras_tarball[0]}" ]]; then
  echo "Error: No tarballs matching oras-cli/*_linux_amd64.tar.gz found" >&2
  exit 1
fi

tar -xzvf "${oras_tarball[0]}" -C oras-cli
oras_cli=$(realpath oras-cli/oras)
if [[ ! -x "${oras_cli}" ]]; then
  echo "Error: oras CLI was not found executable at '${oras_cli}'" >&2
  exit 1
fi

. ci/shared/helpers/run-docker-in-concourse.sh

mkdir -p /usr/local/lib/docker/cli-plugins
cp docker-buildx/buildx-*.linux-amd64 /usr/local/lib/docker/cli-plugins/docker-buildx
chmod 755 /usr/local/lib/docker/cli-plugins/docker-buildx

download_docker "${DOCKER_VERSION}" /tmp/docker
start_docker
trap stop_docker EXIT

basedir=$(dirname "${DOCKERFILE}")
pushd "${basedir}" >/dev/null

docker login -u "${DOCKERHUB_USERNAME}" -p "${DOCKERHUB_PASSWORD}"
docker buildx create --name container --driver=docker-container
docker buildx build . --file Dockerfile --builder container --output type=oci,dest=./image.oci.tar -t "${IMAGE_NAME}" --platform  'linux/amd64'
"${oras_cli}" cp --from-oci-layout ./image.oci.tar:latest "docker.io/${IMAGE_NAME}"
docker buildx imagetools create "docker.io/${IMAGE_NAME}" --tag "docker.io/${IMAGE_NAME}"
