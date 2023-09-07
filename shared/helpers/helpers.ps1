# work around https://github.com/golang/go/issues/27515
function Update-Dir-If-Symlink {
  $dir = $args[0]
    $linkType = (get-item $dir).LinkType
    if ($linkType -ne $null) {
# if linkType is a symbolic link, update to the actual target
      $dir = (get-item $dir).Target
    }
  return $dir
}

function Verify-GCC {
  $dir = $args[0]
  Push-Location $dir
  Test-CommandExists "gcc.exe"
  Pop-Location
}

function Verify-Go {
  $dir = $args[0]
  Push-Location $dir
  Test-CommandExists "go.exe"
    go.exe version
  Pop-Location
}

function Verify-GoVersionMatchBoshRelease {
  $dir = $args[0]
  Push-Location $dir
  $go_version = $(((go version).Split(" ")[2]).Replace("go",""))
  $golang_release_dir = Join-Path $(New-TemporaryDirectory) golang-release
  $package= $(Get-ChildItem "./packages/" -Filter "golang-*windows" -Directory)
  $package_path= $package.FullName
  $package_name = $package.Name
  $spec_lock_value = $(yq .fingerprint "${package_path}/spec.lock")
  git clone --quiet https://github.com/bosh-packages/golang-release "${golang_release_dir}"
  Push-Location "${golang_release_dir}"
  $git_sha = $(git log -S "${spec_lock_value}" --format=format:%H).Split("\n")[0]
  $bosh_release_go_version = $(git show ${git_sha}:"packages/${package_name}/version")
  Pop-Location
  Remove-Item -Recurse -Force $golang_release_dir

  $go_majorminor = $go_version.Split('.')[0..1] -Join '.'
  $bosh_go_majorminor = $bosh_release_go_version.Split('.')[0..1] -Join '.'

  Pop-Location
  if ($go_majorminor -ne $bosh_go_majorminor) {
    Write-Host "Mismatch between windows worker go version ($go_version) and bosh release's go version ($bosh_release_go_version). Please make sure the two match on major and minor"
    exit 1
  }
}

function Verify-GoVet {
  $dir = $args[0]
  Push-Location $dir
  go.exe vet ./...
  if ($LastExitCode -ne 0) {
    exit 1
  }
  Pop-Location
}

function Verify-Ginkgo {
  $dir = $args[0]
  Push-Location $dir
  Test-CommandExists "ginkgo.exe"
  Pop-Location
}

function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

Function Test-CommandExists
{
  Param ($command)
    try {if(Get-Command $command){RETURN}}
  Catch {Write-Host "$command does not exist"; exit 1}
}

Function Expand-Envs
{
    Debug "Expand-Envs Starting"
    ForEach ($entry in "$env:ENVS".Split("`r`n",[System.StringSplitOptions]::RemoveEmptyEntries))
    {
      $items=$entry.Split("=")
        $key=$items[0]
        $value=$items[1]
        Write-Host "Setting env $key=$value"
        Set-Item -Path Env:$key -Value $value
    }
    Debug "Expand-Envs Ending"
}

Function Expand-Functions {
  Debug "Expand-Functions Starting"
  ForEach ($entry in "$env:FUNCTIONS".Split("`r`n", [System.StringSplitOptions]::RemoveEmptyEntries))
  {
    Write-Host "Sourcing: $entry"
    . $entry
  }
  Debug "Expand-Functions Ending"
}

Function Expand-Flags {
  Debug "Expand-Flags Starting"
  $flags=""
  ForEach ($entry in "$env:FLAGS".Split("`r`n", [System.StringSplitOptions]::RemoveEmptyEntries))
  {
    $flags="$flags$entry "
  }
  Debug "Running with flags: $flags"
  Debug "Expand-Flags Ending"
  Return $flags
}

Function Expand-Verifications {
  Debug "Expand-Verifications Starting"
  ForEach ($entry in "$env:VERIFICATIONS".Split("`r`n", [System.StringSplitOptions]::RemoveEmptyEntries))
  {
    Write-Host "Verifying: $entry"
    Invoke-Expression "$entry"
  }
  Debug "Expand-Verifications Ending"
}

Function Debug {
  Param ($msg)
  Add-Content -Path $env:TEMP/$env:TASK_NAME.log -Value $msg
}
