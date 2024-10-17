$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

. "$PSScriptRoot\..\..\..\shared\helpers\helpers.ps1"
if ([System.IO.File]::Exists($env:DEFAULT_PARAMS)) {
    Debug "Extract-Default-Params-For-Task with values from ${env:DEFAULT_PARAMS}"
    Extract-Default-Params-For-Task "$env:DEFAULT_PARAMS"
}

function Run-Docker {
    param([String[]] $cmd)

    docker @cmd
    if ($LASTEXITCODE -ne 0) {
        Exit $LASTEXITCODE
    }
}

function Run
{
    Expand-Envs

    Restart-Service docker

    Run-Docker "--version"

    Write-Host "Building image ${env:IMAGE_NAME}:${env:IMAGE_TAG}"
    Run-Docker "build", "-t", "${env:IMAGE_NAME}:${env:IMAGE_TAG}", "-f", "${env:DOCKERFILE}", "."

    Run-Docker "images", "-a"
    Run-Docker "login", "-u", "${env:DOCKER_USERNAME}", "-p", "${env:DOCKER_PASSWORD}"
    Run-Docker "push", "${env:IMAGE_NAME}:${env:IMAGE_TAG}"
}

Run
