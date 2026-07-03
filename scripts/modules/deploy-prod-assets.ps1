function Assert-ProdEnv {
  $envFile = Join-Path $RepoRoot ".env"
  if (-not (Test-Path $envFile)) {
    throw "Production mode requires .env at the repository root. See docs/prod/production-deployment.md Step 0."
  }

  $required = @("POSTGRES_PASSWORD", "JWT_SECRET", "BASE_URL", "EMAIL_HOST", "EMAIL_PORT", "EMAIL_FROM")
  $content = Get-Content -Raw -Path $envFile
  foreach ($name in $required) {
    if ($content -notmatch "(?m)^$name\s*=") {
      throw "Missing required production variable in .env: $name"
    }
  }
}

function Clear-DirectoryContents {
  param([string]$Path)

  $repoResolved = (Resolve-Path -LiteralPath $RepoRoot).Path
  New-Item -ItemType Directory -Force -Path $Path | Out-Null
  $targetResolved = (Resolve-Path -LiteralPath $Path).Path
  if (-not $targetResolved.StartsWith($repoResolved)) {
    throw "Refusing to clear path outside repository: $targetResolved"
  }

  Get-ChildItem -LiteralPath $targetResolved -Force | Remove-Item -Recurse -Force
}

function Copy-DirectoryContents {
  param(
    [string]$Source,
    [string]$Target
  )

  if (-not (Test-Path $Source)) {
    throw "Missing source directory: $Source"
  }

  Clear-DirectoryContents $Target
  Copy-Item -Path (Join-Path $Source "*") -Destination $Target -Recurse -Force
}

function Build-ProdAssets {
  param([bool]$InstallDeps = $false)

  $npm = Get-NpmCommand

  Write-Step "Building admin frontend"
  Ensure-NpmDeps (Join-Path $RepoRoot "frontend") $InstallDeps
  Invoke-Checked $npm @("run", "build") (Join-Path $RepoRoot "frontend")
  Copy-DirectoryContents (Join-Path $RepoRoot "frontend/dist") (Join-Path $RepoRoot "backend/public/app")

  Write-Step "Building chat widget SDK"
  Ensure-NpmDeps (Join-Path $RepoRoot "chat-bubble") $InstallDeps
  Invoke-Checked $npm @("run", "build") (Join-Path $RepoRoot "chat-bubble")
  Copy-DirectoryContents (Join-Path $RepoRoot "chat-bubble/dist") (Join-Path $RepoRoot "backend/public/sdk")
}
