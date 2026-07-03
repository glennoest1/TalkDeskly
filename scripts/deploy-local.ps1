param(
  [Parameter(Position = 0)]
  [ValidateSet("start", "stop", "restart", "status", "logs", "seed", "build")]
  [string]$Action = "start",

  [switch]$SeedDemoData,
  [switch]$NoSeed,
  [switch]$InstallDeps,
  [switch]$Follow,
  [int]$Tail = 100
)

. "$PSScriptRoot/deploy-common.ps1"

function Seed-Local {
  Write-Step "Seeding local demo data"
  Invoke-Checked "go" @("run", ".", "seed", "run") (Join-Path $RepoRoot "backend")
}

function Stop-Local {
  Stop-LocalProcesses
}

function Show-LocalStatus {
  Write-Step "Local process status"
  Show-LocalProcessStatus

  Test-Http "http://localhost:6721/health"
  Test-Http "http://localhost:5173/"
  Test-Http "http://localhost:3000/"
  Test-Http "http://localhost:8025/"
}

function Show-LocalLogs {
  Write-Step "Local deployment logs"
  Show-LocalProcessLogs ([bool]$Follow) $Tail
}

function Build-Local {
  Write-Step "Preparing local dependencies"
  Ensure-NpmDeps (Join-Path $RepoRoot "frontend") $true
  Ensure-NpmDeps (Join-Path $RepoRoot "chat-bubble") $true
  Write-Info "Go dependencies are resolved by go run/go build from backend/."
}

function Start-Local {
  Write-Step "Starting local dependency containers"
  Invoke-Compose "talkdeskly-local" "docker-compose.dev.yml" @("up", "-d", "postgres", "redis", "mailhog")

  Write-Step "Preparing local host processes"
  Ensure-NpmDeps (Join-Path $RepoRoot "frontend") ([bool]$InstallDeps)
  Ensure-NpmDeps (Join-Path $RepoRoot "chat-bubble") ([bool]$InstallDeps)

  Stop-Local

  $npm = Get-NpmCommand
  $items = @()
  $items += Start-ManagedProcess "backend" "go" @("run", ".") (Join-Path $RepoRoot "backend")
  $items += Start-ManagedProcess "frontend" $npm @("run", "dev", "--", "--host", "0.0.0.0") (Join-Path $RepoRoot "frontend")
  $items += Start-ManagedProcess "chat-bubble" $npm @("run", "dev", "--", "--host", "0.0.0.0", "--port", "3000") (Join-Path $RepoRoot "chat-bubble")
  Save-LocalPids $items

  Write-Step "Waiting for local HTTP endpoints"
  Wait-Http "http://localhost:6721/health"
  Wait-Http "http://localhost:5173/"
  Wait-Http "http://localhost:3000/"
  Wait-Http "http://localhost:8025/"

  if (Test-ShouldSeed $true ([bool]$SeedDemoData) ([bool]$NoSeed)) {
    Seed-Local
  }

  Write-Step "Local deployment ready"
  Write-Info "Admin frontend: http://localhost:5173"
  Write-Info "Chat widget:    http://localhost:3000"
  Write-Info "Backend:        http://localhost:6721"
  Write-Info "MailHog:        http://localhost:8025"
  Write-Info "Logs:           $LogDir"
}

Invoke-DeploymentAction $Action { Start-Local } { Stop-Local } { Show-LocalStatus } { Show-LocalLogs } { Seed-Local } { Build-Local }
