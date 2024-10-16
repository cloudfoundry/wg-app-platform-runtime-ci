$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

$version=(cat version/version)

New-Item -ItemType Directory -Path "$PWD\built-metadata" -Force

docker run `
  -v "$PWD\built-metadata:c:\built-metadata" `
  -w c:\built-metadata `
  --rm `
  "cloudfoundry/windows2016fs:$version" `
  "powershell" "-Command" "Get-Hotfix | Select HotFixID,InstalledOn,Description,InstalledBy > kb-metadata"
if ($LASTEXITCODE -ne 0) {
  throw "failed to build metadata"
}

Add-Content -Path "$PWD\built-metadata\kb-metadata" -Value "Image:cloudfoundry/windows2016fs:$version"

docker run `
  -v "$PWD\built-metadata:c:\built-metadata" `
  -w c:\built-metadata `
  --rm `
  "cloudfoundry/windows2016fs:$version" `
  "powershell" "-Command" "[System.Runtime.InteropServices.RuntimeInformation, mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089]::FrameworkDescription > dotnet-framework.version"
if ($LASTEXITCODE -ne 0) {
  throw "failed to build metadata"
}

Add-Content -Path "$PWD\built-metadata\kb-metadata" -Value (cat "$PWD\built-metadata\dotnet-framework.version") 
Get-Content "$PWD\built-metadata\kb-metadata"
