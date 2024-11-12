FROM mcr.microsoft.com/windows/nanoserver:1809

LABEL org.cloudfoundry.groot-windows-test-link.dockerfile.url="https://github.com/cloudfoundry/wg-app-platform-runtime-ci/blob/main/winc-release/dockerfiles/link/Dockerfile"
LABEL org.cloudfoundry.groot-windows-test-link.notes.md="Used by winc-release \
"

USER Administrator
RUN mkdir C:\temp\test & echo hello > C:\temp\test\hello
RUN mklink C:\temp\symlinkfile C:\temp\test\hello
RUN mklink /H C:\temp\hardlinkfile C:\temp\test\hello
RUN mklink /D C:\temp\symlinkdir C:\temp\test
RUN mklink /J C:\temp\junctiondir C:\temp\test
