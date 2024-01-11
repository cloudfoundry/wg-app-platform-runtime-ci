$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

cd redis-buildpack
git checkout "$env:BRANCH"

Invoke-WebRequest 'https://dot.net/v1/dotnet-install.ps1' -OutFile 'dotnet-install.ps1';
./dotnet-install.ps1 -InstallDir '~/.dotnet' -Version '3.1.201' ;

./build.ps1 Test --stack Windows
exit $LASTEXITCODE
