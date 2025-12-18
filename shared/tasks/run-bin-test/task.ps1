$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

. "$PSScriptRoot\..\..\..\shared\helpers\helpers.ps1"
if ([System.IO.File]::Exists($env:DEFAULT_PARAMS)) {
    Debug "Extract-Default-Params-For-Task with values from ${env:DEFAULT_PARAMS}"
    Extract-Default-Params-For-Task "$env:DEFAULT_PARAMS"
}
$env:TASK_NAME="$(Get-Random)"

function Run
{

    $env:TEMP="/var/vcap/data/tmp"
    $env:TMP="/var/vcap/data/tmp"
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
    if (Test-Path "./bin/test.ps1") {
        Debug "Runing ./bin/test.ps1 for repo/$env:DIR"
        $f = "$(Expand-Flags)"
        echo $f
cat "$env:TEMP/$env:TASK_NAME.log"
        ./bin/test.ps1 $(Expand-Flags)
    } else {
        Debug "Missing ./bin/test.ps1. Running ginkgo by default for repo/$env:DIR"
        Invoke-Expression "go run github.com/onsi/ginkgo/v2/ginkgo $(Expand-Flags)"
        if ($LASTEXITCODE -ne 0){
            throw "failed"
        }
    }
    Pop-Location
}

Run
