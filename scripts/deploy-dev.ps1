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

function Seed-Dev {
  Write-Step "Seeding Docker development demo data"
  Invoke-Compose "talkdeskly-dev" "docker-compose.dev.yml" @("exec", "-T", "backend", "go", "run", ".", "seed", "run")
}

function Start-Dev {
  Write-Step "Starting Docker development stack"
  Invoke-Compose "talkdeskly-dev" "docker-compose.dev.yml" @("up", "-d", "--build")

  Write-Step "Waiting for development HTTP endpoints"
  Wait-Http "http://localhost:6721/health"
  Wait-Http "http://localhost:3001/"
  Wait-Http "http://localhost:3000/"
  Wait-Http "http://localhost:8025/"

  if (Test-ShouldSeed $true ([bool]$SeedDemoData) ([bool]$NoSeed)) {
    Seed-Dev
  }

  Write-Step "Development deployment ready"
  Write-Info "Admin frontend: http://localhost:3001"
  Write-Info "Chat widget:    http://localhost:3000"
  Write-Info "Backend:        http://localhost:6721"
  Write-Info "MailHog:        http://localhost:8025"
}

function Build-Dev {
  Write-Step "Building Docker development images"
  Invoke-Compose "talkdeskly-dev" "docker-compose.dev.yml" @("build")
}

function Stop-Dev {
  Write-Step "Stopping Docker development stack"
  Invoke-Compose "talkdeskly-dev" "docker-compose.dev.yml" @("down")
}

function Show-DevLogs {
  Write-Step "Docker development logs"
  Assert-ComposeProjectHasContainers "talkdeskly-dev" "docker-compose.dev.yml" "make dev"
  Invoke-ComposeLogs "talkdeskly-dev" "docker-compose.dev.yml" $Tail ([bool]$Follow)
}

function Show-DevStatus {
  Write-Step "Docker development status"
  Invoke-Compose "talkdeskly-dev" "docker-compose.dev.yml" @("ps")
  Assert-ComposeProjectHasContainers "talkdeskly-dev" "docker-compose.dev.yml" "make dev"
  Test-Http "http://localhost:6721/health"
  Test-Http "http://localhost:3001/"
  Test-Http "http://localhost:3000/"
  Test-Http "http://localhost:8025/"
}

Invoke-DeploymentAction $Action { Start-Dev } { Stop-Dev } { Show-DevStatus } { Show-DevLogs } { Seed-Dev } { Build-Dev }
