ARG GCC_IMAGE="gcc"

FROM ${GCC_IMAGE} AS usemem-builder
COPY garden-rootfs/usemem.c ./
RUN gcc -o ./usemem --static ./usemem.c

FROM scratch

COPY --from=usemem-builder  /usemem /bin/usemem
