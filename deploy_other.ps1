# Roku Deployment PowerShell Script
# This script builds the Jellyfin Roku app and deploys it to your device.

$RokuIP = "192.168.1.181"
$RokuPass = "whit"
$ZipPath = "out\JellyVibe.zip"

Write-Host "`n=== JellyVibe Deployment (Other) ===" -ForegroundColor Yellow
Write-Host "Target: $RokuIP" -ForegroundColor Gray

Write-Host "`n[1/2] Building package..." -ForegroundColor Cyan
npm run build

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERROR] Build command failed. Check build_errors.txt for details." -ForegroundColor Red
    pause
    exit 1
}

# Verify zip was created
if (!(Test-Path $ZipPath)) {
    Write-Host "`n[ERROR] Build completed but zip file was not found at: $ZipPath" -ForegroundColor Red
    Write-Host "Make sure 'outFile' is correctly set in bsconfig.json" -ForegroundColor Yellow
    pause
    exit 1
}

$ZipSize = (Get-Item $ZipPath).Length / 1KB
Write-Host ("Build successful! Package size: {0:N0} KB" -f $ZipSize) -ForegroundColor Green

# Use curl.exe explicitly to avoid PowerShell alias (Invoke-WebRequest)
$curl = "curl.exe"
if (!(Get-Command $curl -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] curl.exe is not installed or not available on PATH." -ForegroundColor Red
    pause
    exit 1
}

Write-Host "`n[2/2] Sideloading to Roku at $RokuIP..." -ForegroundColor Cyan

# Run curl without -f to see the error, and capture output
& $curl -sS --user "rokudev:$RokuPass" --digest -F "archive=@$ZipPath" -F "mysubmit=Replace" "http://$RokuIP/plugin_install"

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERROR] Deployment failed with exit code $LASTEXITCODE." -ForegroundColor Red
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "  1. Incorrect Roku IP ($RokuIP)"
    Write-Host "  2. Incorrect Developer Password"
    Write-Host "  3. Roku is not in Developer Mode"
    Write-Host "  4. Network firewall blocking port 80"
    pause
    exit 1
}

Write-Host "`nDeployment Complete! App should be launching on your Roku." -ForegroundColor Green
pause

