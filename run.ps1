# run.ps1 - Quick script to run docker compose with proper environment
# Usage: .\run.ps1 -Environment dev
# Or:    .\run.ps1 dev

param(
    [string]$Target = "up",
    [string]$ENV = "dev"
)

$ErrorActionPreference = "Stop"

$envFile = ".$ENV"
$secretsFile = ".$ENV.secrets"

if (-not (Test-Path "$envFile")) {
    Write-Error "Config file not found: $envFile"
    exit 1
}

Write-Host "Loading environment: $ENV"

Get-Content "$envFile" | ForEach-Object {
    if ($_ -match '^([^#=]+)=(.+)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        [Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
}

if (Test-Path "$secretsFile") {
    Get-Content "$secretsFile" | ForEach-Object {
        if ($_ -match '^([^#=]+)=(.+)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
}

$dcProfiles = ""
if ($ENV -eq "local") {
    $dcProfiles = "--profile local"
}

$cmd = "docker compose -f docker-compose.yml $dcProfiles $Target -d"
Write-Host "Running: $cmd"

Invoke-Expression $cmd