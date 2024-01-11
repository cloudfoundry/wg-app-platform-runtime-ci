$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

cd web-config-buildpack
git checkout "$env:BRANCH"

./build.ps1 Test --stack Windows