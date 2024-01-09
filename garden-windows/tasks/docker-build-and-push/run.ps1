$ProgressPreference="SilentlyContinue"
$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

function Run-Docker {
  param([String[]] $cmd)

  docker @cmd
  if ($LASTEXITCODE -ne 0) {
    Exit $LASTEXITCODE
  }
}

$repoPath = (Resolve-Path repo).Path

restart-service docker

$version=(cat version/number)
$digest=(cat upstream-image/digest)

mkdir buildDir
cp $env:DOCKERFILE buildDir\Dockerfile
cp git-setup\Git-*-64-bit.exe buildDir\
cp vcredist-ucrt\vcredist-ucrt.x64.exe buildDir\
cp vcredist-ucrt-x86\vcredist-ucrt.x86.exe buildDir\
cp vcredist-2010\vcredist-2010.x64.exe buildDir\
cp vcredist-2010-x86\vcredist-2010.x86.exe buildDir\

if (Test-Path dotnet-48-installer) {
  cp dotnet-48-installer\dotnet-48-installer.exe buildDir\
}

# download.microsoft.com requires TLS 1.0 (it is disabled by default in the stemcell).
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client" -Value 1 -Name 'Enabled' -Type DWORD
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client" -Value 0 -Name 'DisabledByDefault' -Type DWORD
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server" -Value 1 -Name 'Enabled' -Type DWORD
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server" -Value 0 -Name 'DisabledByDefault' -Type DWORD

curl -UseBasicParsing -Outfile buildDir\rewrite.msi -Uri "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"

cd buildDir

Write-Host "Building image using the '$digest' provided by Concourse"
Run-Docker "--version"
Run-Docker "build", "--build-arg", "BASE_IMAGE_DIGEST=@$digest", "-t", "$env:IMAGE_NAME", "-t", "${env:IMAGE_NAME}:$version", "-t", "${env:IMAGE_NAME}:${env:OS_VERSION}", "--pull", "."

# output systeminfo including hotfixes for documentation
Run-Docker "run", "${env:IMAGE_NAME}:$version", "cmd", "/c", "systeminfo"
Run-Docker "run", "${env:IMAGE_NAME}:$version", "powershell", "(get-childitem C:\Windows\System32\msvcr100.dll).VersionInfo | Select-Object -Property FileDescription,ProductVersion"
Run-Docker "run", "${env:IMAGE_NAME}:$version", "powershell", "(get-childitem C:\Windows\System32\vcruntime140.dll).VersionInfo | Select-Object -Property FileDescription,ProductVersion"

$env:TEST_CANDIDATE_IMAGE=$env:IMAGE_NAME
$env:VERSION_TAG=$env:OS_VERSION

cd $repoPath
ginkgo.exe -v
if ($LASTEXITCODE -ne 0) {
  Exit $LASTEXITCODE
}

Run-Docker "images", "-a"
Run-Docker "login", "-u", "$env:DOCKER_USERNAME", "-p", "$env:DOCKER_PASSWORD"
Run-Docker "push", "${env:IMAGE_NAME}:latest"
Run-Docker "push", "${env:IMAGE_NAME}:$version"
Run-Docker "push", "${env:IMAGE_NAME}:${env:OS_VERSION}"
