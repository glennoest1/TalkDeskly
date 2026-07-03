function Get-LocalPids {
  if (-not (Test-Path $PidFile)) {
    return @()
  }

  $raw = Get-Content -Raw -Path $PidFile
  if ([string]::IsNullOrWhiteSpace($raw)) {
    return @()
  }

  $items = $raw | ConvertFrom-Json
  if ($null -eq $items) {
    return @()
  }
  if ($items -is [array]) {
    return $items
  }
  return @($items)
}

function Save-LocalPids {
  param([object[]]$Items)
  Ensure-StateDir
  $Items | ConvertTo-Json -Depth 4 | Set-Content -Path $PidFile -Encoding utf8
}

function Start-ManagedProcess {
  param(
    [string]$Name,
    [string]$Command,
    [string[]]$Arguments,
    [string]$WorkingDirectory
  )

  Ensure-StateDir

  $stdout = Join-Path $LogDir "$Name.out.log"
  $stderr = Join-Path $LogDir "$Name.err.log"
  $startArgs = @{
    FilePath = $Command
    ArgumentList = $Arguments
    WorkingDirectory = $WorkingDirectory
    RedirectStandardOutput = $stdout
    RedirectStandardError = $stderr
    PassThru = $true
  }

  if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $startArgs.WindowStyle = "Hidden"
  }

  $process = Start-Process @startArgs
  Write-Info ("Started {0} pid={1}" -f $Name, $process.Id)
  return [pscustomobject]@{
    name = $Name
    pid = $process.Id
    cwd = $WorkingDirectory
    stdout = $stdout
    stderr = $stderr
  }
}

function Stop-LocalProcesses {
  Write-Step "Stopping local host processes"
  $items = Get-LocalPids
  foreach ($item in $items) {
    try {
      $process = Get-Process -Id $item.pid -ErrorAction Stop
      Stop-Process -Id $process.Id -Force
      Write-Info ("Stopped {0} pid={1}" -f $item.name, $item.pid)
    } catch {
      Write-Info ("Already stopped: {0} pid={1}" -f $item.name, $item.pid)
    }
  }

  if (Test-Path $PidFile) {
    Remove-Item -LiteralPath $PidFile -Force
  }
}

function Show-LocalProcessStatus {
  $items = Get-LocalPids
  if ($items.Count -eq 0) {
    Write-Info "No local process state found."
  }

  foreach ($item in $items) {
    $running = $false
    try {
      Get-Process -Id $item.pid -ErrorAction Stop | Out-Null
      $running = $true
    } catch {
      $running = $false
    }
    Write-Info ("{0} pid={1} running={2}" -f $item.name, $item.pid, $running)
    Write-Info ("logs: {0} | {1}" -f $item.stdout, $item.stderr)
  }
}

function Show-LocalProcessLogs {
  param(
    [bool]$Follow = $false,
    [int]$Tail = 100
  )

  Ensure-StateDir
  $logFiles = @(
    Join-Path $LogDir "backend.out.log"
    Join-Path $LogDir "backend.err.log"
    Join-Path $LogDir "frontend.out.log"
    Join-Path $LogDir "frontend.err.log"
    Join-Path $LogDir "chat-bubble.out.log"
    Join-Path $LogDir "chat-bubble.err.log"
  )

  $existing = @($logFiles | Where-Object { Test-Path $_ })
  if ($existing.Count -eq 0) {
    Write-Info "No local logs found. Run make local first."
    return
  }

  if ($Follow) {
    Get-Content -Path $existing -Tail $Tail -Wait
  } else {
    foreach ($file in $existing) {
      Write-Host ""
      Write-Host "--- $file"
      Get-Content -Path $file -Tail $Tail
    }
  }
}
