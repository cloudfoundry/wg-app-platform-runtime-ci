ARG BUSYBOX_VERSION
FROM gcc
COPY usemem.c ./
RUN gcc -o ./usemem --static ./usemem.c

FROM golang
ENV CGO_ENABLED=0
RUN go install bazil.org/fuse/examples/hellofs@latest


FROM busybox:${BUSYBOX_VERSION}

ARG BUSYBOX_VERSION

ADD seed /etc/seed
RUN chmod 0644 /etc/seed
COPY --from=0  /usemem /bin/usemem
COPY --from=1 /go/bin/hellofs /usr/bin/hellofs

RUN echo "BUSYBOX_VERSION: ${BUSYBOX_VERSION}" >  /base-image-version.txt

RUN adduser -D testuser
