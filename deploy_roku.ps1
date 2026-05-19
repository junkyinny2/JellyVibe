# Roku Deployment PowerShell Script
# This script builds the JellyVibe Roku app and deploys to your device.
#
# !!! WARNING: The Living Room Roku IP is 192.168.1.196. DO NOT CHANGE IT !!!

$RokuPass = "whit"
$RokuUser = "rokudev"
$ConfigFile = Join-Path $PSScriptRoot "bsconfig.deploy.json"
$Config = $null

if (Test-Path $ConfigFile) {
    try {
        $Config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        if ($Config.password) { $RokuPass = $Config.password }
        if ($Config.username) { $RokuUser = $Config.username }
        Write-Host "[INFO] Loaded deployment config from $ConfigFile" -ForegroundColor Gray
    } catch {
        Write-Host "[WARNING] Could not parse $ConfigFile. Using fallbacks." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== JellyVibe Deployment ===" -ForegroundColor Yellow

# Ask for Roku IP (Enter defaults to 192.168.1.196)
# !!! DO NOT CHANGE: Living Room Roku = 192.168.1.196 !!!
$defaultIP = "192.168.1.196"
$RokuIP = Read-Host "Enter Roku IP (default: $defaultIP)"
if ($RokuIP -eq "") { $RokuIP = $defaultIP }

Write-Host ""
Write-Host "[1/3] Cleaning old build artifacts..." -ForegroundColor Cyan
npx rimraf build/ out/
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARNING] Clean step had issues, continuing..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[2/3] Building package..." -ForegroundColor Cyan
$buildOutput = npx bsc --project $ConfigFile 2>&1
$buildExit = $LASTEXITCODE

if ($buildExit -ne 0) {
    Write-Host "[ERROR] Build failed with exit code $buildExit" -ForegroundColor Red
    Write-Host $buildOutput
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

if (-not (Test-Connection -ComputerName $RokuIP -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
    Write-Host "[WARNING] Roku at $RokuIP is not responding to ping. Deployment may fail." -ForegroundColor Yellow
}

$uploadUrl = "http://$RokuIP/plugin_install"
$result = & "curl.exe" -sS --user "$RokuUser`:$RokuPass" --digest -F "archive=@$zipPath" -F "mysubmit=Replace" $uploadUrl 2>&1
$uploadExit = $LASTEXITCODE

if ($uploadExit -ne 0) {
    Write-Host "[ERROR] Sideload failed with exit code $uploadExit" -ForegroundColor Red
    Write-Host $result
    pause
    exit 1
}

Write-Host ""
Write-Host "Deployment Complete! App should be launching on your Roku." -ForegroundColor Green
Write-Host "Starting Roku Dev Mode Monitor..." -ForegroundColor Yellow
& "$PSScriptRoot\rokudebug.ps1" $RokuIP