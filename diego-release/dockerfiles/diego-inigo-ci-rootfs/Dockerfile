FROM ubuntu:jammy

# jq: for stupid simple bash servers
# curl: for hitting test servers
# git: for testing git buildpacks
# fuse: for inigo style vizzini tests
RUN \
  apt-get update && \
  apt-get -y install \
    curl \
    git \
    jq \
    fuse \
    netcat-openbsd \
  && \
  apt-get clean

RUN useradd -m testuser

RUN useradd -m vcap

LABEL org.cloudfoundry.diego-inigo-ci-rootfs.dockerfile.url="https://github.com/cloudfoundry/wg-app-platform-runtime-ci/blob/main/diego-release/dockerfiles/diego-inigo-ci-rootfs/Dockerfile"
LABEL org.cloudfoundry.diego-inigo-ci-rootfs.notes.md="Used by diego-release within \
code.cloudfoundry.org/inigo \
"
