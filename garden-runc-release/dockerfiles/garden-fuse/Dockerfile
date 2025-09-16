ARG DEBIAN_IMAGE="debian"
FROM ${DEBIAN_IMAGE}

LABEL org.cloudfoundry.garden-fuse.dockerfile.url="https://github.com/cloudfoundry/wg-app-platform-runtime-ci/blob/main/garden-runc-release/dockerfiles/garden-fuse/Dockerfile"
LABEL org.cloudfoundry.garden-fuse.notes.md="Used by garden-runc-release \
"

RUN apt-get update && apt-get -y install \
  libfuse-dev \
  strace \
  bc \
  gcc \
  attr \
  iputils-ping \
  pkg-config \
  libcap2-bin 

RUN cd /usr/share/doc/libfuse-dev/examples && \
  bash -c "gcc -Wall hello.c $(pkg-config fuse --cflags --libs) -o /usr/bin/hellofs"


RUN useradd -m alice
# set required capabilitites for raw sockets
RUN setcap cap_net_raw+ep /usr/bin/ping
