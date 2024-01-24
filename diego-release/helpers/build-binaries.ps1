. "$PSScriptRoot\..\..\shared\helpers\helpers.ps1"

function Build-Nats-Server
{
    Param
        (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $Source,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $Target
        )

        Verify-Go
        Set-TemporaryDirectory 
        $BuiltDir=$(Split-Path $Target -Leaf)
        $Target = Update-Dir-If-Symlink "$Target"
        $Target = Join-Path "$Target" "nats-server"
        New-Item -ItemType Directory -Force -Path "$Target"

        Push-Location "$Source"
        go.exe build -o "$Target\run.exe" .
        if ($LastExitCode -ne 0) {
            exit 1
        }

    Pop-Location

    $PS1FILE='$env:NATS_SERVER_BINARY="$PWD/{0}"' -f "$BuiltDir\nats-server\run.exe" 
        Set-Content -Path "$Target/run.ps1" -Value $PS1FILE -Encoding Asci
}
