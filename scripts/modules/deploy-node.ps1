function Get-NpmCommand {
  if ($IsWindows -or $env:OS -eq "Windows_NT") {
    return "npm.cmd"
  }
  return "npm"
}

function Ensure-NpmDeps {
  param(
    [string]$ProjectDir,
    [bool]$ForceInstall = $false
  )

  $nodeModules = Join-Path $ProjectDir "node_modules"
  if ($ForceInstall -or -not (Test-Path $nodeModules)) {
    Invoke-Checked (Get-NpmCommand) @("install") $ProjectDir
  } else {
    Write-Info "Dependencies already present: $nodeModules"
  }
}
