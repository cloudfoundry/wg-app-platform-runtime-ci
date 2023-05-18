$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

. "$PSScriptRoot\..\..\..\shared\helpers\helpers.ps1"

function Run
{
    . Expand-Functions

    Get-ChildItem -Path built-binaries -Filter *.ps1 -Recurse -File -Name -ErrorAction SilentlyContinue | ForEach-Object {
        $PS1File = "./built-binaries/$_"
        Write-Host "Sourcing: $PS1File"
        if ( $env:DEBUG -ne "false" ) {
            Get-Content -Path $PS1File
        }
        . $PS1File
    }

    Expand-Envs

    Verify-Go
    Verify-Ginkgo

    Push-Location "repo/$env:DIR"
    go vet ./...
    ./bin/test.ps1
    Pop-Location
}

Run
