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
  Test-CommandExists "gcc.exe"
}

function Verify-Go {
  Test-CommandExists "go.exe"
    go.exe version
}

function Verify-Ginkgo {
  Test-CommandExists "ginkgo.exe"
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

Function Debug {
  Param ($msg)
  if ( $env:DEBUG -ne "false" ) {
    Write-Host "$msg"
  }
}
