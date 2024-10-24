FROM mcr.microsoft.com/windows/nanoserver:1809

LABEL org.cloudfoundry.groot-windows-test-whiteout.dockerfile.url="https://github.com/cloudfoundry/wg-app-platform-runtime-ci/blob/main/winc-release/dockerfiles/whiteout/Dockerfile"
LABEL org.cloudfoundry.groot-windows-test-whiteout.notes.md="Used by winc-release \
"

RUN mkdir C:\temp\test & echo hello > C:\temp\test\hello
RUN del /f C:\temp\test\hello

RUN echo hello2 > C:\temp\test\hello2
