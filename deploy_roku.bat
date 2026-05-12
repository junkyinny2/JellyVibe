@echo off
setlocal

:: Roku Deployment Script do not change ip
:: This script builds the Jellyfin Roku app and deploys it to your device using curl.

set ROKU_IP=192.168.1.196
set ROKU_PASS=whit
set ZIP_PATH=out\JellyVibe.zip

echo [1/2] Building package...
call npm run build
if errorlevel 1 (
    echo.
    echo [ERROR] Build command failed.
    pause
    exit /b 1
)

if not exist "%ZIP_PATH%" (
    echo.
    echo [ERROR] Build failed, zip file not found at "%ZIP_PATH%"
    pause
    exit /b 1
)

:: Check if curl.exe is available (Windows 10/11 has it by default)
where curl.exe >nul 2>&1
if errorlevel 1 (
    echo [ERROR] curl.exe is not installed or not available on PATH.
    pause
    exit /b 1
)

echo [2/2] Sideloading to Roku at %ROKU_IP%...
:: Using curl.exe explicitly to avoid PowerShell alias conflicts
:: Removed >nul to allow seeing the response/errors
curl.exe -sS -f --user "rokudev:%ROKU_PASS%" --digest -F "archive=@%ZIP_PATH%" -F "mysubmit=Replace" "http://%ROKU_IP%/plugin_install"
if errorlevel 1 (
    echo.
    echo [ERROR] Deployment failed. 
    echo Check your Roku IP %ROKU_IP%, Password, and Developer Mode status.
    pause
    exit /b 1
)


echo.
echo Deployment Complete!
pause

