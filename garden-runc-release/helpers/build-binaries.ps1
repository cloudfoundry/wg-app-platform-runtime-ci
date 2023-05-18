. "$PSScriptRoot\..\..\shared\helpers\helpers.ps1"

function Build-Winit
{
    Param
        (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $Source,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $Target
        )

        Verify-Go

        $BuiltDir=$(Split-Path $Target -Leaf)
        $Target = Update-Dir-If-Symlink "$Target"
        $Target = Join-Path "$Target" "winit"
        New-Item -ItemType Directory -Force -Path "$Target"

        Push-Location "$Source"
        go.exe build -o "$Target\run.exe" main.go
        if ($LastExitCode -ne 0) {
            exit $LastExitCode
        }

    Pop-Location
    $PS1FILE='$env:WINIT_BINARY="$PWD/{0}"' -f "$BuiltDir/winit/run.exe"
        Set-Content -Path "$Target/run.ps1" -Value $PS1FILE -Encoding Asci
}

function Build-Gdn
{
    Param
        (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $Source,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $Target
        )

        Verify-Go

        $BuiltDir=$(Split-Path $Target -Leaf)
        $Target = Update-Dir-If-Symlink "$Target"
        $Target = Join-Path "$Target" "gdn"
        New-Item -ItemType Directory -Force -Path "$Target"

        Push-Location "$Source"

        go.exe build -o "$Target\run.exe" -tags "hnsAcls" .
        if ($LastExitCode -ne 0) {
            exit $LastExitCode
        }
    Pop-Location
    $PS1FILE='$env:GDN_BINARY="$PWD/{0}"
$env:GDN_DEPOT_PATH="/var/vcap/data/tmp/depot"
$env:GDN_OUT_LOG_FILE="$PWD/{1}"
$env:GDN_ERR_LOG_FILE="$PWD/{2}"
$env:GDN_BIND_IP="127.0.0.1"
$env:GDN_BIND_PORT=8888' -f "$BuiltDir/gdn/run.exe", "$BuiltDir/gdn/out.log", "$BuiltDir/gdn/err.log"
        Set-Content -Path "$Target/run.ps1" -Value $PS1FILE -Encoding Asci
}
