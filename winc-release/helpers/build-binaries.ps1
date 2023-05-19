. "$PSScriptRoot\..\..\shared\helpers\helpers.ps1"

function Build-Groot
{
    Param
        (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $Source,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $Target
        )

        Verify-Go
        Verify-GCC

        $BuiltDir=$(Split-Path $Target -Leaf)
        $Target = Update-Dir-If-Symlink "$Target"
        $Target = Join-Path "$Target" "groot-windows"
        New-Item -ItemType Directory -Force -Path "$Target"

        Push-Location "$Source"
        go.exe build -o "$Target\run.exe" main.go
        if ($LastExitCode -ne 0) {
            exit 1
        }

    gcc.exe -c ".\volume\quota\quota.c" -o "$env:TEMP\quota.o"
        if ($LastExitCode -ne 0) {
            exit 1
        }

    gcc.exe -shared -o "$Target\quota.dll" "$env:TEMP\quota.o" -lole32 -loleaut32
        if ($LastExitCode -ne 0) {
            exit 1
        }
    Pop-Location

    Set-Content -Path "$Target/config.yml" -value "log_level: debug"

    $PS1FILE='$env:GROOT_BINARY="$PWD/{0}"
$env:GROOT_IMAGE_STORE="\var\vcap\data\tmp\groot"
$env:GROOT_CONFIG="$PWD/{1}"' -f "$BuiltDir\groot-windows\run.exe", "$BuiltDir/groot-windows/config.yml"
        Set-Content -Path "$Target/run.ps1" -Value $PS1FILE -Encoding Asci
}

function Build-Winc-Network
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
        $Target = Join-Path "$Target" "winc-network"
        New-Item -ItemType Directory -Force -Path "$Target"

        Push-Location "$Source"

        go.exe build -o "$Target\run.exe" -tags "hnsAcls" .
        if ($LastExitCode -ne 0) {
            exit 1
        }
    Pop-Location
      $Config = '{"mtu": 0, "network_name": "winc-nat", "subnet_range": "172.30.0.0/22", "gateway_address": "172.30.0.1"}'
        Set-Content -Path "$Target\config.json" -value $Config

    $PS1FILE='$env:WINC_NETWORK_BINARY="$PWD/{0}"
$env:WINC_NETWORK_CONFIG="$PWD/{1}"
$env:WINC_NETWORK_LOG_FILE="$PWD/{2}"' -f "$BuiltDir/winc-network/run.exe","$BuiltDir/winc-network/config.json", "$BuiltDir/winc-network/out.log"
        Set-Content -Path "$Target/run.ps1" -Value $PS1FILE -Encoding Asci
}

function Build-Winc
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
        $Target = Join-Path "$Target" "winc"
        New-Item -ItemType Directory -Force -Path "$Target"

        Push-Location "$Source"

        go.exe build -o "$Target\run.exe" .
        if ($LastExitCode -ne 0) {
            exit 1
        }
    Pop-Location
        $PS1FILE='$env:WINC_BINARY="$PWD/{0}"' -f "$BuiltDir/winc/run.exe"
        Set-Content -Path "$Target/run.ps1" -Value $PS1FILE -Encoding Asci
}

function Build-Nstar
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
        $Target = Join-Path "$Target" "nstar"
        New-Item -ItemType Directory -Force -Path "$Target"
        Push-Location "$Source"

        go.exe build -o "$Target\run.exe" .
        if ($LastExitCode -ne 0) {
            exit 1
        }
    Pop-Location
        $PS1FILE='$env:NSTAR_BINARY="$PWD/{0}"' -f "$BuiltDir/nstar/run.exe"
        Set-Content -Path "$Target/run.ps1" -Value $PS1FILE -Encoding Asci
}
