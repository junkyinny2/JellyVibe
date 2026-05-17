# Roku Deployment PowerShell Script
# This script builds the Jellyfin Roku app and deploys to your device.
# Usage: .\deploy_roku.ps1 [-Target "living"|"bedroom"]

param(
    [string]$Target = ""
)

$RokuPass = "whit"
$ConfigFile = "bsconfig.deploy.json"

$RokuUser = "rokudev"
if (Test-Path $ConfigFile) {
    try {
        $config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        if ($config.password) { $RokuPass = $config.password }
        if ($config.username) { $RokuUser = $config.username }
        Write-Host "[INFO] Loaded deployment config from $ConfigFile" -ForegroundColor Gray
    } catch {
        Write-Host "[WARNING] Could not parse $ConfigFile. Using fallbacks." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== JellyVibe Deployment ===" -ForegroundColor Yellow

# Select Roku target
if ($Target -eq "") {
    Write-Host "Select Roku target:"
    Write-Host "  1) 192.168.1.196 (Living Room)"
    Write-Host "  2) 192.168.1.181 (Bedroom)"
    Write-Host ""
    $choice = Read-Host "Enter 1 or 2"
    switch ($choice) {
        "1" { $RokuIP = "192.168.1.196" }
        "2" { $RokuIP = "192.168.1.181" }
        default { $RokuIP = "192.168.1.196" }
    }
} else {
    switch -Wildcard ($Target.ToLower()) {
        "bedroom" { $RokuIP = "192.168.1.181" }
        default   { $RokuIP = "192.168.1.196" }
    }
}
Write-Host "Target: $RokuIP" -ForegroundColor Gray
Write-Host "Config: $ConfigFile" -ForegroundColor Gray

Write-Host ""
Write-Host "[1/3] Cleaning old build artifacts..." -ForegroundColor Cyan
npx rimraf build/ out/

Write-Host ""
Write-Host "[2/3] Building package..." -ForegroundColor Cyan
$buildResult = npx bsc --project $ConfigFile 2>&1
$buildExit = $LASTEXITCODE

if ($buildExit -ne 0) {
    Write-Host "[ERROR] Build failed with exit code $buildExit" -ForegroundColor Red
    Write-Host $buildResult
    pause
    exit 1
}

$zipPath = "out\JellyVibe.zip"
if (-not (Test-Path $zipPath)) {
    Write-Host "[ERROR] Build completed but zip not found at: $zipPath" -ForegroundColor Red
    pause
    exit 1
}

$zipSize = (Get-Item $zipPath).Length / 1KB
Write-Host "Build complete! Package size: $([math]::Round($zipSize, 1)) KB" -ForegroundColor Green

Write-Host ""
Write-Host "[3/3] Sideloading to Roku at $RokuIP..." -ForegroundColor Cyan

if (-not (Test-Connection -ComputerName $RokuIP -Count 1 -Quiet)) {
    Write-Host "[WARNING] Roku at $RokuIP is not responding to ping. Deployment may fail." -ForegroundColor Yellow
}

$curl = "curl.exe"
if (-not (Get-Command $curl -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] curl.exe not found on PATH." -ForegroundColor Red
    pause
    exit 1
}

# Use digest auth to sideload the zip
$uploadUrl = "http://$RokuIP/plugin_install"
$result = & $curl -sS --user "$RokuUser`:$RokuPass" --digest -F "archive=@$zipPath" -F "mysubmit=Replace" $uploadUrl 2>&1
$uploadExit = $LASTEXITCODE

if ($uploadExit -ne 0) {
    Write-Host "[ERROR] Sideload failed with exit code $uploadExit" -ForegroundColor Red
    Write-Host $result
    pause
    exit 1
}

Write-Host ""
Write-Host "Deployment Complete! App should be launching on your Roku." -ForegroundColor Green
pause
