#!/bin/sh

set -e -x

DOCKERFILE="${DOCKERFILE_PATH%/Dockerfile}/Dockerfile"

if ! test -f "${DOCKERFILE}"; then
  echo "Error: ${DOCKERFILE} was not found" >&2
  exit 1
fi

oras_tarball=$(find oras-cli -name "*_linux_amd64.tar.gz" | head)
if ! test -f "${oras_tarball}"; then
  echo "Error: No tarballs matching oras-cli/*_linux_amd64.tar.gz found" >&2
  exit 1
fi

tar -xzvf "${oras_tarball}" -C oras-cli
oras_cli="oras-cli/oras"
if ! test -x "${oras_cli}"; then
  echo "Error: oras CLI was not found executable at '${oras_cli}'" >&2
  exit 1
fi

basedir=$(dirname "${DOCKERFILE}")
cd "${basedir}"

docker buildx build . --file Dockerfile --output type=oci,dest=./image.oci.tar -t "${IMAGE_NAME}" --platform  'linux/amd64'
"${oras_cli}"cp --from-oci-layout ./image.oci.tar:latest "docker.io/${IMAGE_NAME}"
docker buildx imagetools create "docker.io/${IMAGE_NAME}" --tag "docker.io/${IMAGE_NAME}"
