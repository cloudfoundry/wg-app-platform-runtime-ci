$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

. "$PSScriptRoot\..\..\..\shared\helpers\helpers.ps1"

function Run
{
    . Expand-Functions

    Get-ChildItem -Path built-binaries -Filter *.ps1 -Recurse -File -Name -ErrorAction SilentlyContinue | ForEach-Object {
        $PS1File = "./built-binaries/$_"
        Write-Host "Sourcing: $PS1File"
        Debug {Get-Content -Path $PS1File}
        . $PS1File
    }

    Expand-Envs

    Expand-Verifications

    Push-Location "repo/$env:DIR"
    ./bin/test.ps1 $(Expand-Flags)
    Pop-Location
}

Run
