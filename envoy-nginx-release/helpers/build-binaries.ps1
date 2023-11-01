. "$PSScriptRoot\..\..\shared\helpers\helpers.ps1"

function Build-Proxy
{
    Param
        (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $Source,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $Target
        )

        Verify-Go

        $env:TEMP="/var/vcap/data/tmp"
        $env:TMP="/var/vcap/data/tmp"
        $BuiltDir=$(Split-Path $Target -Leaf)
        $Target = Update-Dir-If-Symlink "$Target"
        $Target = Join-Path "$Target" "proxy"
        New-Item -ItemType Directory -Force -Path "$Target"

        Push-Location "$Source"
        bosh sync-blobs
        Expand-Archive -Force -Path "blobs\envoy-nginx\envoy-nginx*.zip" -DestinationPath "$Target"
        Pop-Location

        Push-Location "$Source/src/code.cloudfoundry.org/envoy-nginx"
        go.exe build -o "$Target\run.exe" main.go
        if ($LastExitCode -ne 0) {
            exit 1
        }
        Pop-Location

        $PS1FILE='$env:PROXY_BINARY="$PWD/{0}"' -f "$BuiltDir/proxy/run.exe"
        Set-Content -Path "$Target/run.ps1" -Value $PS1FILE -Encoding Asci
}
