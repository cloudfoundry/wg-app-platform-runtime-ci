$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

Add-Type -AssemblyName System.IO.Compression.FileSystem
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$env:TMP = "C:\var\vcap\data\tmp"
$env:TEMP = "C:\var\vcap\data\tmp"
$download_file = "$env:TEMP\golang.zip"
$go_destination = "C:\tools"

Remove-Item -Recurse -Force -ErrorAction Ignore $download_file
Remove-Item -Recurse -Force -ErrorAction Ignore "$go_destination\go"
mkdir -Force $go_destination

Invoke-WebRequest -UseBasicParsing "https://dl.google.com/go/go$env:GO_VERSION.windows-amd64.zip" -OutFile $download_file

$path = (Get-ChildItem $download_file).FullName

if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
  Expand-Archive -Force -Path $path -DestinationPath $go_destination
} else {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::ExtractToDirectory($path, $go_destination)
}

$OldPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
$AddedFolder="$go_destination\go\bin"
$NewPath=$OldPath+';'+$AddedFolder
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath

Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name GOROOT -Value "$go_destination\go"
