$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

mkdir "$env:EPHEMERAL_DISK_TEMP_PATH" -ea 0
$env:TEMP = $env:TMP = $env:GOTMPDIR = $env:EPHEMERAL_DISK_TEMP_PATH
$env:GOCACHE = "$env:EPHEMERAL_DISK_TEMP_PATH\go-build"
$env:USERPROFILE = "$env:EPHEMERAL_DISK_TEMP_PATH"

function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

$TEMPDIR=(New-TemporaryDirectory)
New-Item -ItemType Directory -Path "$TEMPDIR\go" -Force
$env:GOPATH=(Resolve-Path "$TEMPDIR\go").Path
$PACKAGE="$env:GOPATH\src\$env:IMPORT_PATH"
New-Item -ItemType Directory -Path $PACKAGE -Force

robocopy.exe /E "repo" "$PACKAGE"
if ($LASTEXITCODE -ge 8) {
    Write-Error "robocopy.exe /E repo/* $PACKAGE"
}

# get tar on the path
$env:PATH="$env:PATH;C:\var\vcap\bosh\bin"

go install github.com/onsi/ginkgo/v2/ginkgo@latest

cd "$PACKAGE"
go get ./...
& "$env:GOPATH/bin/ginkgo.exe" -nodes $env:NODES -r -race -keep-going -randomize-suites
Exit $LastExitCode
