FROM debian

RUN apt-get update && apt-get -y install \
  libfuse-dev \
  gcc \
  pkg-config

RUN cd /usr/share/doc/libfuse-dev/examples && \
  bash -c "gcc -Wall hello.c $(pkg-config fuse --cflags --libs) -o /usr/bin/hellofs"
