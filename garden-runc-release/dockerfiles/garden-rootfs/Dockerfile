ARG BUSYBOX_VERSION
FROM gcc as usemem-builder
COPY usemem.c ./
RUN gcc -o ./usemem --static ./usemem.c

FROM golang as throttled-or-not-builder
WORKDIR /go/src/app
ENV CGO_ENABLED 0
COPY throttled-or-not .
RUN go build -o /throttled-or-not /go/src/app/throttled-or-not.go

FROM busybox:${BUSYBOX_VERSION}

ARG BUSYBOX_VERSION

ADD seed /etc/seed
RUN chmod 0644 /etc/seed
COPY --from=usemem-builder  /usemem /bin/usemem

RUN echo "BUSYBOX_VERSION: ${BUSYBOX_VERSION}" >  /base-image-version.txt

RUN adduser -D testuser

# copied from cfgarden/empty
ADD hello hello
ADD allo allo

# copied from cfgarden/hardlink
RUN touch file && mkdir -p /first/second && ln file /first/second/file-link && mkdir -p /first/second && touch /first/second/file2 && ln /first/second/file2 file-link2

# copied from cfgarden/non-writtable-file
RUN mkdir -p test && touch test/hello && chmod 555 test/hello
RUN chmod 777 test/hello && echo "walla" > /test/hello && chmod 555 /test/hello

# copied from cfgarden/non-writtable-folder
RUN mkdir -p test && touch test/hello && chmod 555 test

# copied from cfgarden/opaque-whiteout
RUN mkdir /var/somedir
RUN rm -r /var && mkdir /var && touch /var/istillexist
# copied from cfgarden/opaque-whiteout-regression-image
RUN mkdir -p /test/foo && \
   touch /test/foo/1 /test/foo/2 && \
   mkdir -p /test/foo/bar && \
   touch /test/foo/bar/3
RUN rm -rf /test/foo/*

# for cfgarden/with-whiteout
RUN touch file-to-be-deleted
RUN touch existing-file
RUN mkdir -p folder
RUN rm file-to-be-deleted
RUN rm -rf folder

# copied from cfgarden/overwrite-link
RUN echo "source!" > /etc/link-source
RUN echo "WHAT?" > /tmp/symlink
RUN rm /tmp/symlink && ln -s /etc/link-source /tmp/symlink

# copied from cfgarden/throttled-or-not
COPY --from=throttled-or-not-builder /throttled-or-not /bin/throttled-or-not

# copied from cfgarden/with-process-env
ENV PATH /usr/local/bin:/usr/bin:/bin:/from-dockerfile
ENV TEST test-from-dockerfile
ENV TEST second-test-from-dockerfile:$TEST

# copied from cfgarden/with-user-with-group
RUN addgroup gardenparty2 -g 1011
RUN addgroup gardenparty -g 1010
RUN adduser -D -G gardenparty alice
RUN adduser alice gardenparty2

# copied from cfgarden/with-volume
RUN mkdir /etc/foo
VOLUME /etc/foo

LABEL org.cloudfoundry.garden-rootfs.dockerfile.url="https://github.com/cloudfoundry/wg-app-platform-runtime-ci/blob/main/garden-runc-release/dockerfiles/garden-rootfs/Dockerfile"
LABEL org.cloudfoundry.garden-rootfs.notes.md="Used by garden-runc-release \
"
