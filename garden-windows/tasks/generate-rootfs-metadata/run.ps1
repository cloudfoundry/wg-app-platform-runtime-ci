$ProgressPreference="SilentlyContinue"
$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

$version=(cat image-version/version)

docker run `
  -v "$PWD\artifacts:c:\artifacts" `
  -w c:\artifacts `
  --rm `
  "cloudfoundry/windows2016fs:$version" `
  "powershell" "-Command" "Get-Hotfix | Select HotFixID,InstalledOn,Description,InstalledBy > kb-metadata"
if ($LASTEXITCODE -ne 0) {
  Exit $LASTEXITCODE
}

Write-Output "$env:IMAGE_NAME:$version"
Get-Content "$PWD\artifacts\kb-metadata"


