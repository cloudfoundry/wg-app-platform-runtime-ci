$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

. "$PSScriptRoot\..\..\..\shared\helpers\helpers.ps1"
$env:TASK_NAME="$(Get-Random)"

function Run
{
    $env:TEMP="/var/vcap/data/tmp"
    $env:TMP="/var/vcap/data/tmp"
    Clean-GoCache
}

Run
