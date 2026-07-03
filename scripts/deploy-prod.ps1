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

function Seed-Prod {
  Write-Step "Seeding production demo data"
  Invoke-Compose "talkdeskly-prod" "docker-compose.prod.yml" @("exec", "-T", "backend", "./talkdeskly", "seed", "run")
}

function Start-Prod {
  Assert-ProdEnv
  Build-ProdAssets ([bool]$InstallDeps)

  Write-Step "Starting production stack"
  Invoke-Compose "talkdeskly-prod" "docker-compose.prod.yml" @("up", "-d", "--build")

  Write-Step "Waiting for production HTTP endpoint"
  Wait-Http "http://localhost:8080/health"
  Wait-Http "http://localhost:8080/"
  Wait-Http "http://localhost:8080/sdk/sdk.iife.js"

  if (Test-ShouldSeed $false ([bool]$SeedDemoData) ([bool]$NoSeed)) {
    Seed-Prod
  }

  Write-Step "Production deployment ready"
  Write-Info "Backend/admin: http://localhost:8080"
  Write-Info "SDK:           http://localhost:8080/sdk/sdk.iife.js"
}

function Build-Prod {
  Assert-ProdEnv
  Build-ProdAssets ([bool]$InstallDeps)
  Write-Step "Building production Docker image"
  Invoke-Compose "talkdeskly-prod" "docker-compose.prod.yml" @("build", "backend")
}

function Stop-Prod {
  Write-Step "Stopping production stack"
  Invoke-Compose "talkdeskly-prod" "docker-compose.prod.yml" @("down")
}

function Show-ProdLogs {
  Assert-ProdEnv
  Write-Step "Production logs"
  Assert-ComposeProjectHasContainers "talkdeskly-prod" "docker-compose.prod.yml" "make prod"
  Invoke-ComposeLogs "talkdeskly-prod" "docker-compose.prod.yml" $Tail ([bool]$Follow)
}

function Show-ProdStatus {
  Assert-ProdEnv
  Write-Step "Production status"
  Invoke-Compose "talkdeskly-prod" "docker-compose.prod.yml" @("ps")
  Assert-ComposeProjectHasContainers "talkdeskly-prod" "docker-compose.prod.yml" "make prod"
  Test-Http "http://localhost:8080/health"
  Test-Http "http://localhost:8080/"
  Test-Http "http://localhost:8080/sdk/sdk.iife.js"
}

Invoke-DeploymentAction $Action { Start-Prod } { Stop-Prod } { Show-ProdStatus } { Show-ProdLogs } { Seed-Prod } { Build-Prod }
