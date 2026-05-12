@echo off
setlocal

echo ========================================
echo   Jellyvibe Roku Deployment Script
echo ========================================
echo.

:: Check if Node.js is installed
where node >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Node.js is not installed or not in your PATH.
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

:: Check if node_modules exists
if not exist node_modules (
    echo node_modules not found. Running npm install...
    call npm install
)

echo [1/1] Building and Deploying to Roku...
echo This will clean old files, compile BrighterScript, 
echo zip the package, and upload it to 192.168.1.196.
echo.

:: Run the deploy script from package.json
call npm run deploy

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Deployment failed. 
    echo Make sure your Roku is at 192.168.1.196 and Developer Mode is enabled.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ========================================
echo   SUCCESS: Jellyvibe is on your Roku!
echo ========================================
pause
