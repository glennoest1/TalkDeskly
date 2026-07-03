function Invoke-Compose {
  param(
    [string]$ProjectName,
    [string]$ComposeFile,
    [string[]]$Arguments
  )

  Invoke-Checked "docker" (@("compose", "-p", $ProjectName, "-f", $ComposeFile) + $Arguments)
}

function Invoke-ComposeLogs {
  param(
    [string]$ProjectName,
    [string]$ComposeFile,
    [int]$Tail = 100,
    [bool]$Follow = $false
  )

  $args = @("logs", "--tail", "$Tail")
  if ($Follow) {
    $args += "-f"
  }
  Invoke-Compose $ProjectName $ComposeFile $args
}

function Get-ComposeContainerIds {
  param(
    [string]$ProjectName,
    [string]$ComposeFile
  )

  Push-Location $RepoRoot
  try {
    $ids = & docker compose -p $ProjectName -f $ComposeFile ps -q
    if ($LASTEXITCODE -ne 0) {
      throw "Command failed with exit code ${LASTEXITCODE}: docker compose -p $ProjectName -f $ComposeFile ps -q"
    }
    return @($ids | Where-Object { $_ })
  } finally {
    Pop-Location
  }
}

function Assert-ComposeProjectHasContainers {
  param(
    [string]$ProjectName,
    [string]$ComposeFile,
    [string]$StartCommand
  )

  $containerIds = Get-ComposeContainerIds $ProjectName $ComposeFile
  if ($containerIds.Count -eq 0) {
    throw "No running containers found for Compose project '$ProjectName'. Run '$StartCommand' first. If endpoints still respond, another Compose project may be holding the same ports."
  }
}
