$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

. "$PSScriptRoot\..\..\..\shared\helpers\helpers.ps1"
if ([System.IO.File]::Exists($env:DEFAULT_PARAMS)) {
    Debug "Extract-Default-Params-For-Task with values from ${env:DEFAULT_PARAMS}"
    Extract-Default-Params-For-Task "$env:DEFAULT_PARAMS"
}

function Run
{
    . Expand-Functions

    $Target=Join-Path "$PWD" "built-binaries"

    ForEach ($entry in "$env:MAPPING".Split("`r`n", [System.StringSplitOptions]::RemoveEmptyEntries))
    {
        $Config=$entry.Split("=")
        $Function=$Config[0]
        $Source='repo/{0}' -f $Config[1]
        Write-Host "Executing: $Function -Source $Source -Target $Target"
        & $Function -Source $Source -Target "$Target"
    }
}

Run
