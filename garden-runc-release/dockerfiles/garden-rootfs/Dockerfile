ARG BUSYBOX_VERSION
FROM gcc
COPY usemem.c ./
RUN gcc -o ./usemem --static ./usemem.c

FROM busybox:${BUSYBOX_VERSION}

ARG BUSYBOX_VERSION

ADD seed /etc/seed
RUN chmod 0644 /etc/seed
COPY --from=0  /usemem /bin/usemem

RUN echo "BUSYBOX_VERSION: ${BUSYBOX_VERSION}" >  /base-image-version.txt

RUN adduser -D testuser

LABEL org.cloudfoundry.garden-rootfs.dockerfile.url="https://github.com/cloudfoundry/wg-app-platform-runtime-ci/blob/main/garden-runc-release/dockerfiles/garden-rootfs/Dockerfile"
LABEL org.cloudfoundry.garden-rootfs.notes.md="Used by garden-runc-release \
"
