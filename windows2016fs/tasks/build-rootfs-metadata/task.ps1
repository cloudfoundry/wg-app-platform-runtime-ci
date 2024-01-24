$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

$version=(cat version/version)

docker run `
  -v "$PWD\built-metadata:c:\built-metadata" `
  -w c:\built-metadata`
  --rm `
  "cloudfoundry/windows2016fs:$version" `
  "powershell" "-Command" "Get-Hotfix | Select HotFixID,InstalledOn,Description,InstalledBy > kb-metadata"
if ($LASTEXITCODE -ne 0) {
  throw "failed to build metadata"
}

Write-Output "$env:IMAGE_NAME:$version"
Get-Content "$PWD\built-metadata\kb-metadata"


