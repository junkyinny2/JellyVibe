param(
    [string]$Message = ""
)

$repoDir = Split-Path -Parent $PSCommandPath
Set-Location $repoDir

if (-not (Test-Path ".git")) {
    Write-Host "Not a git repository: $repoDir" -ForegroundColor Red
    exit 1
}

$remote = git remote
if (-not $remote) {
    Write-Host "No git remote found" -ForegroundColor Red
    exit 1
}

git add -A

if ([string]::IsNullOrWhiteSpace($Message)) {
    $Message = "Update JellyVibe"
}

git commit -m $Message

if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) {
    Write-Host "Commit failed" -ForegroundColor Red
    exit 1
}

git push origin

if ($LASTEXITCODE -eq 0) {
    Write-Host "Pushed to origin successfully." -ForegroundColor Green
} else {
    Write-Host "Push failed" -ForegroundColor Red
}
