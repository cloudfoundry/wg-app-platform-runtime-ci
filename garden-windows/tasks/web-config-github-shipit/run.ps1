$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

Push-Location web-config-buildpack
  git checkout "$env:BRANCH"

  .\build.ps1 --configuration Release --git-hub-token "$env:GITHUB_AUTH_TOKEN" --target Release --stack windows
  if ($LASTEXITCODE -ne 0) {
    Exit $LASTEXITCODE
  }
Pop-Location

cp web-config-buildpack/artifacts/Web.Config.Transform.Buildpack-*.zip artifacts