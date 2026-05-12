# Multi-Version Roku Deployment Script
# Allows deploying stable and dev versions side-by-side on the same Roku device

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("stable", "dev")]
    [string]$Version,
    
    [string]$RokuIP = "192.168.1.196",
    [string]$RokuUser = "rokudev",
    [string]$RokuPass = "whit"
)

$ErrorActionPreference = "Stop"

# Configuration for each version
$configs = @{
    stable = @{
        Title = "jellyvibe"
        Suffix = ""
        PackageType = "zip"
        IconFHD = "channel-poster_fhd.png"
        IconHD = "channel-poster_hd.png"
        IconSD = "channel-poster_sd.png"
    }
    dev = @{
        Title = "jellyvibe-dev"
        Suffix = "-dev"
        PackageType = "pkg"
        IconFHD = "channel-poster_fhd_dev.png"
        IconHD = "channel-poster_hd_dev.png"
        IconSD = "channel-poster_sd_dev.png"
    }
}

$config = $configs[$Version]
$backupDir = ".manifest-backups"

function Backup-Manifest {
    if (!(Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "$backupDir\manifest_$timestamp.backup"
    Copy-Item "manifest" $backupFile
    Write-Host "Backed up manifest to $backupFile"
    return $backupFile
}

function Restore-Manifest($backupFile) {
    if ($backupFile -and (Test-Path $backupFile)) {
        Copy-Item $backupFile "manifest" -Force
        Write-Host "Restored manifest from backup"
    }
}

function Update-ManifestForVersion($version) {
    $content = Get-Content "manifest" -Raw
    
    # Update title
    $content = $content -replace "^title=.*$", "title=$($config.Title)"
    
    # Update icons based on version
    $content = $content -replace "mm_icon_focus_fhd=.*$", "mm_icon_focus_fhd=pkg:/images/$($config.IconFHD)"
    $content = $content -replace "mm_icon_focus_hd=.*$", "mm_icon_focus_hd=pkg:/images/$($config.IconHD)"
    $content = $content -replace "mm_icon_focus_sd=.*$", "mm_icon_focus_sd=pkg:/images/$($config.IconSD)"
    
    # Add version suffix to build_version for dev
    if ($version -eq "dev") {
        $content = $content -replace "^build_version=.*$", "build_version=999"
    }
    
    Set-Content "manifest" $content -NoNewline
    Write-Host "Updated manifest for $version version (title: $($config.Title))"
}

function Build-Project {
    Write-Host "Building project..." -ForegroundColor Cyan
    npm run build 2>&1 | ForEach-Object {
        if ($_ -match "error|Error") {
            Write-Host $_ -ForegroundColor Red
        } else {
            Write-Host $_
        }
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed!"
    }
}

function Deploy-ToRoku($version) {
    $packageFile = if ($version -eq "stable") { "out\JellyVibe.zip" } else { "out\JellyVibe.pkg" }
    $packageName = Split-Path $packageFile -Leaf
    
    if (!(Test-Path $packageFile)) {
        # For dev version, we need to create a pkg file
        if ($version -eq "dev") {
            # Convert zip to pkg (Roku package format)
            $zipFile = "out\JellyVibe.zip"
            if (Test-Path $zipFile) {
                Copy-Item $zipFile $packageFile -Force
                Write-Host "Created $packageFile from $zipFile"
            } else {
                throw "Package file not found: $zipFile"
            }
        } else {
            throw "Package file not found: $packageFile"
        }
    }
    
    Write-Host "Deploying $version version ($packageName) to Roku at $RokuIP..." -ForegroundColor Cyan
    
    $uri = "http://$RokuIP/plugin_install"
    $result = curl -sS -f --user "$RokuUser`:$RokuPass" --digest `
        -F "archive=@$packageFile" `
        -F "mysubmit=Replace" `
        $uri 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully deployed $version version!" -ForegroundColor Green
    } else {
        Write-Host "Deployment failed: $result" -ForegroundColor Red
        throw "Deployment failed"
    }
}

# Main execution
try {
    Write-Host "=== Deploying $Version Version ===" -ForegroundColor Yellow
    
    # Backup current manifest
    $backup = Backup-Manifest
    
    # Update manifest for target version
    Update-ManifestForVersion $Version
    
    # Build
    Build-Project
    
    # Deploy
    Deploy-ToRoku $Version
    
    Write-Host "`n=== Deployment Complete ===" -ForegroundColor Green
    Write-Host "You can now find '$($config.Title)' on your Roku home screen"
    
} catch {
    Write-Host "`nERROR: $_" -ForegroundColor Red
    exit 1
} finally {
    # Always restore original manifest
    Write-Host "`nRestoring original manifest..."
    git checkout manifest 2>&1 | Out-Null
    Write-Host "Done!"
}
