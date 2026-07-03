$ErrorActionPreference = "Stop"

$DeployScriptDir = Split-Path -Parent $PSCommandPath
$RepoRoot = Split-Path -Parent $DeployScriptDir
$StateDir = Join-Path $RepoRoot ".deploy"
$LogDir = Join-Path $StateDir "logs"
$PidFile = Join-Path $StateDir "local-pids.json"
$DeployModuleDir = Join-Path $DeployScriptDir "modules"

. (Join-Path $DeployModuleDir "deploy-core.ps1")
. (Join-Path $DeployModuleDir "deploy-http.ps1")
. (Join-Path $DeployModuleDir "deploy-node.ps1")
. (Join-Path $DeployModuleDir "deploy-compose.ps1")
. (Join-Path $DeployModuleDir "deploy-local-process.ps1")
. (Join-Path $DeployModuleDir "deploy-prod-assets.ps1")
