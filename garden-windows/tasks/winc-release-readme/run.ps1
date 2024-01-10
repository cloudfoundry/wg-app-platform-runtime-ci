$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

go.exe version

$README_FILE = "$PWD\generated-readme\README.md"
$README = @"
# winc-release

A [BOSH](http://docs.cloudfoundry.org/bosh/) release for deploying [winc](https://github.com/cloudfoundry-incubator/winc)

The following powershell script can be used to quickly create a new container.
`n
"@


push-location winc-release

$env:GOBIN="$PWD\bin"
$env:PATH="$env:GOBIN;$env:PATH"

$ephemeral_disk_temp_path="C:\var\vcap\data\tmp"
mkdir "$ephemeral_disk_temp_path" -ea 0
$env:TEMP = $env:TMP = $ephemeral_disk_temp_path
$env:GROOT_IMAGE_STORE = "$ephemeral_disk_temp_path\groot"

Write-Host "Build Binaries"
Start-Process -FilePath "powershell.exe" `
    -ArgumentList "-ExecutionPolicy ByPass -File .\src\build-binaries.ps1" `
    -Wait -PassThru -NoNewWindow

$NEXT = @"
 `n
- Build required binaries

``````
. ".\src\build-binaries.ps1"
``````
 `n
"@
$README = [string]::join(" ",$README, $NEXT)

Write-Host "Create Container"
$containerId = [guid]::NewGuid().Guid
Start-Process -FilePath "powershell.exe" `
    -ArgumentList "-ExecutionPolicy ByPass -File .\src\create-container.ps1 $containerId" `
    -Wait -PassThru -NoNewWindow
$NEXT = @"
 `n
- Create Container with an optional containerId as an argument. This requires
  setting ``WINC_TEST_ROOTFS`` to an image (e.g. $env:WINC_TEST_ROOTFS)
  and ``GROOT_IMAGE_STORE`` (e.g  $env:GROOT_IMAGE_STORE)

``````
Start-Process -FilePath "powershell.exe" `
    -ArgumentList "-ExecutionPolicy ByPass -File .\src\create-container.ps1 <CONTAINER_ID>" `
    -Wait -PassThru -NoNewWindow
``````
 `n
"@
$README = [string]::join(" ",$README, $NEXT)

Write-Host "Get Container State"
$errFile="$env:TEMP\err.txt"
$outFile="$env:TEMP\out.txt"
Start-Process -FilePath "winc" `
    -ArgumentList "state $containerId" `
    -RedirectStandardError $errFile `
    -RedirectStandardOutput $outFile `
    -Wait -PassThru -NoNewWindow
$state=(Get-Content -Path "$outFile" | ConvertFrom-Json).Status
if ($state -ne "created") {
    Write-Error "Container is not created"
} else {
    Write-Host "Container is created"
}
$NEXT = @"
 `n
- Get Container state

``````
winc state <CONTAINER_ID>
``````
 `n
"@
$README = [string]::join(" ",$README, $NEXT)

$bundle=(Get-Content -Path "$outFile" | ConvertFrom-Json).Bundle
$validBundleConfig = (Get-Content -Path "$bundle\config.json" | ConvertFrom-Json)
$validBundleConfig.root.path = "\\?\Volume{guid-xxxx-xxxx-xxxxxxxxxxxxx}"
$validBundleConfig = ($validBundleConfig | ConvertTo-Json -depth 80)

Write-Host "Delete Container"
Start-Process -FilePath "powershell.exe" `
    -ArgumentList "-ExecutionPolicy ByPass -File .\src\delete-container.ps1 $containerId" `
    -Wait -PassThru -NoNewWindow
$NEXT = @"
 `n
- Delete Container

``````
Start-Process -FilePath "powershell.exe" `
    -ArgumentList "-ExecutionPolicy ByPass -File .\src\delete-container.ps1 <CONTAINER_ID>" `
    -Wait -PassThru -NoNewWindow
``````
 `n
"@
$README = [string]::join(" ",$README, $NEXT)

Write-Host "Get Container State"
Start-Process -FilePath "winc" `
    -ArgumentList "state $containerId" `
    -RedirectStandardError $errFile `
    -RedirectStandardOutput $outFile `
    -Wait -PassThru

$state=(Get-Content -Path "$errFile")
if ($state -ne "container not found: $containerId") {
    Write-Error "Container is still created"
} else {
    Write-Host "Container is deleted"
}

$NEXT = @"
 `n
### Example of a valid bundle config.json

``````json
$validBundleConfig
``````
 `n
"@
$README = [string]::join(" ", $README, $NEXT)

pop-location

Set-Content -Value $README -Path "$README_FILE" -Encoding Ascii -Force


