function Write-Step {
  param([string]$Message)
  Write-Host ""
  Write-Host "==> $Message"
}

function Write-Info {
  param([string]$Message)
  Write-Host "    $Message"
}

function Ensure-StateDir {
  New-Item -ItemType Directory -Force -Path $StateDir | Out-Null
  New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
}

function Invoke-Checked {
  param(
    [string]$FilePath,
    [string[]]$Arguments,
    [string]$WorkingDirectory = $RepoRoot
  )

  Write-Info ("{0} {1}" -f $FilePath, ($Arguments -join " "))
  Push-Location $WorkingDirectory
  try {
    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) {
      throw "Command failed with exit code ${LASTEXITCODE}: $FilePath $($Arguments -join ' ')"
    }
  } finally {
    Pop-Location
  }
}

function Test-ShouldSeed {
  param(
    [bool]$DefaultSeed,
    [bool]$SeedDemoData,
    [bool]$NoSeed
  )

  if ($NoSeed) { return $false }
  if ($SeedDemoData) { return $true }
  return $DefaultSeed
}

function Invoke-DeploymentAction {
  param(
    [ValidateSet("start", "stop", "restart", "status", "logs", "seed", "build")]
    [string]$Action,
    [scriptblock]$Start,
    [scriptblock]$Stop,
    [scriptblock]$Status,
    [scriptblock]$Logs,
    [scriptblock]$Seed,
    [scriptblock]$Build
  )

  Push-Location $RepoRoot
  try {
    if ($Action -eq "start") {
      & $Start
    } elseif ($Action -eq "stop") {
      & $Stop
    } elseif ($Action -eq "restart") {
      & $Stop
      & $Start
    } elseif ($Action -eq "status") {
      & $Status
    } elseif ($Action -eq "logs") {
      & $Logs
    } elseif ($Action -eq "seed") {
      & $Seed
    } else {
      & $Build
    }
  } finally {
    Pop-Location
  }
}
