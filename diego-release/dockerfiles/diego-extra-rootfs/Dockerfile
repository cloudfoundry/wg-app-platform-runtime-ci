FROM  ubuntu:jammy

LABEL org.cloudfoundry.diego-extra-rootfs.dockerfile.url="https://github.com/cloudfoundry/wg-app-platform-runtime-ci/blob/main/diego-release/dockerfiles/diego-extra-rootfs/Dockerfile"
LABEL org.cloudfoundry.diego-extra-rootfs.notes.md="Used by diego-release in inigo. .tar file is checked in under fixtures dir\
"

RUN apt update && apt install -y netcat
RUN useradd -m testuser
RUN useradd -m vcap

