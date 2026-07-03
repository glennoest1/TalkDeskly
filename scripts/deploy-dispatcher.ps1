param(
  [Parameter(Position = 0)]
  [ValidateSet("local", "dev", "prod")]
  [string]$Mode = "dev",

  [Parameter(Position = 1)]
  [ValidateSet("start", "stop", "restart", "status", "logs", "seed", "build")]
  [string]$Action = "start",

  [switch]$SeedDemoData,
  [switch]$NoSeed,
  [switch]$InstallDeps,
  [switch]$Follow,
  [int]$Tail = 100
)

$ErrorActionPreference = "Stop"

$modeScript = Join-Path $PSScriptRoot "deploy-$Mode.ps1"
if (-not (Test-Path $modeScript)) {
  throw "Unsupported deployment mode script: $modeScript"
}

$forward = @{ Action = $Action }
if ($SeedDemoData) { $forward.SeedDemoData = $true }
if ($NoSeed) { $forward.NoSeed = $true }
if ($InstallDeps) { $forward.InstallDeps = $true }
if ($Follow) { $forward.Follow = $true }
if ($PSBoundParameters.ContainsKey("Tail")) { $forward.Tail = $Tail }

& $modeScript @forward
exit $LASTEXITCODE
