FROM golang
COPY dockerapp.go /tmp/
ENV CGO_ENABLED 0
RUN go build -o /dockerapp /tmp/dockerapp.go

FROM busybox

ENV VCAP_APPLICATION {}
ENV BAD_QUOTE \'
ENV BAD_SHELL \$1
ENV HOME /home/some_docker_user
ENV SOME_VAR some_docker_value
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/myapp/bin

EXPOSE 8080

COPY --from=0 /dockerapp /myapp/bin/dockerapp
WORKDIR /myapp

RUN adduser -D vcap

# set user to 'nobody' so that it is non-root
USER 65534

LABEL org.cloudfoundry.diego-docker-app.dockerfile.url="https://github.com/cloudfoundry/wg-app-platform-runtime-ci/blob/main/diego-release/dockerfiles/diego-docker-app/Dockerfile"
LABEL org.cloudfoundry.diego-docker-app.notes.md="Used by diego-release within \
code.cloudfoundry.org/dockerapplifecycle \
code.cloudfoundry.org/ecrhelper \
"

CMD ["dockerapp"]
