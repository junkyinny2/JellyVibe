@echo off
setlocal

:: Default commit message if none provided
set "commit_msg=%~1"
if "%commit_msg%"=="" set "commit_msg=Update layout and fix bugs"

echo Adding changes...
git add .

echo Committing changes...
git commit -m "%commit_msg%"

echo Pushing to GitHub...
git push

echo Done!
pause
