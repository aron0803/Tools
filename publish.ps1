<# 
.SYNOPSIS
    Ron Tools - Auto Publish Script
.DESCRIPTION
    1. Scan File directory for .zip files
    2. Create/Update GitHub Release and upload files
    3. Generate index.html download page
    4. Push to GitHub
#>

param(
    [string]$Version = "",
    [string]$Message = "Update tools",
    [switch]$SkipRelease = $false
)

# Settings
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$FileDir = Join-Path $ScriptDir "File"
$DocsDir = Join-Path $ScriptDir "docs"
$ToolsJsonPath = Join-Path $ScriptDir "tools.json"
$IndexHtmlPath = Join-Path $DocsDir "index.html"
$RepoOwner = "aron0803"
$RepoName = "Tools"

# Output functions
function Write-Step {
    param([string]$Step, [string]$Message)
    Write-Host ""
    Write-Host "[$Step] " -ForegroundColor Cyan -NoNewline
    Write-Host $Message -ForegroundColor White
}

function Write-OK {
    param([string]$Message)
    Write-Host "  [OK] " -ForegroundColor Green -NoNewline
    Write-Host $Message -ForegroundColor White
}

function Write-Err {
    param([string]$Message)
    Write-Host "  [X] " -ForegroundColor Red -NoNewline
    Write-Host $Message -ForegroundColor White
}

function Write-Info {
    param([string]$Message)
    Write-Host "  -> " -ForegroundColor Yellow -NoNewline
    Write-Host $Message -ForegroundColor Gray
}

# Title
Clear-Host
Write-Host ""
Write-Host "  =========================================" -ForegroundColor Magenta
Write-Host "       Ron Tools - Publish System          " -ForegroundColor Magenta
Write-Host "  =========================================" -ForegroundColor Magenta
Write-Host ""

# Step 1: Check prerequisites
Write-Step "1/7" "Checking environment..."

# Check Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Err "Git not found, please install Git first"
    exit 1
}
Write-OK "Git installed"

# Check GitHub CLI
$hasGhCli = Get-Command gh -ErrorAction SilentlyContinue
if ($hasGhCli) {
    Write-OK "GitHub CLI installed"
    
    # Check if logged in
    $authStatus = gh auth status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-OK "GitHub CLI logged in"
    }
    else {
        Write-Err "GitHub CLI not logged in, run: gh auth login"
        $SkipRelease = $true
    }
}
else {
    Write-Info "GitHub CLI not installed, skipping Release feature"
    Write-Info "Install: winget install GitHub.cli"
    $SkipRelease = $true
}

# Step 2: Scan .zip files
Write-Step "2/7" "Scanning File directory..."

if (-not (Test-Path $FileDir)) {
    New-Item -ItemType Directory -Path $FileDir -Force | Out-Null
    Write-Info "Created File directory"
}

$zipFiles = Get-ChildItem -Path $FileDir -Filter "*.zip" -File
if ($zipFiles.Count -eq 0) {
    Write-Err "No .zip files found in File directory"
    exit 1
}

Write-OK "Found $($zipFiles.Count) .zip file(s):"
foreach ($file in $zipFiles) {
    $sizeKB = [math]::Round($file.Length / 1KB, 2)
    Write-Info "$($file.Name) ($sizeKB KB)"
}

# Step 3: Read tool config
Write-Step "3/7" "Reading tool config..."

$toolsConfig = @{
    siteName        = "Ron Tools"
    siteDescription = "Useful tools collection"
    author          = "Ron"
    tools           = @{}
}

if (Test-Path $ToolsJsonPath) {
    try {
        $jsonContent = Get-Content $ToolsJsonPath -Raw -Encoding UTF8
        $toolsConfig = $jsonContent | ConvertFrom-Json
        Write-OK "Loaded tools.json"
    }
    catch {
        Write-Err "Cannot parse tools.json: $_"
    }
}

# Step 4: Generate version
Write-Step "4/7" "Preparing release..."

if ([string]::IsNullOrEmpty($Version)) {
    $Version = Get-Date -Format "yyyy.MM.dd"
}
$TagName = "v$Version"

Write-Info "Version: $Version"
Write-Info "Tag: $TagName"

# Step 5: Create/Update GitHub Release
if (-not $SkipRelease -and $hasGhCli) {
    Write-Step "5/7" "Uploading to GitHub Release..."
    
    # Check if Release exists
    $releaseExists = gh release view $TagName 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Info "Release $TagName exists, updating files..."
        
        # Delete old assets
        foreach ($file in $zipFiles) {
            gh release delete-asset $TagName $file.Name --yes 2>$null
        }
        
        # Upload new files
        foreach ($file in $zipFiles) {
            Write-Info "Uploading $($file.Name)..."
            gh release upload $TagName $file.FullName --clobber
            if ($LASTEXITCODE -eq 0) {
                Write-OK "Uploaded $($file.Name)"
            }
            else {
                Write-Err "Failed to upload $($file.Name)"
            }
        }
    }
    else {
        Write-Info "Creating new Release: $TagName"
        
        # Create Release and upload all files
        $fileArgs = $zipFiles | ForEach-Object { $_.FullName }
        gh release create $TagName $fileArgs --title "Ron Tools $Version" --notes $Message
        
        if ($LASTEXITCODE -eq 0) {
            Write-OK "Release created successfully"
        }
        else {
            Write-Err "Failed to create Release"
        }
    }
}
else {
    Write-Step "5/7" "Skipping GitHub Release..."
    Write-Info "Using direct link mode"
}

# Step 6: Generate index.html
Write-Step "6/7" "Generating download page..."

# Ensure docs directory exists
if (-not (Test-Path $DocsDir)) {
    New-Item -ItemType Directory -Path $DocsDir -Force | Out-Null
}

# Build tools data array
$toolsDataArray = @()
foreach ($file in $zipFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    
    # Get tool info from config
    $toolInfo = $null
    if ($toolsConfig.tools -and $toolsConfig.tools.PSObject.Properties[$baseName]) {
        $toolInfo = $toolsConfig.tools.$baseName
    }
    
    # Determine download URL
    if (-not $SkipRelease -and $hasGhCli) {
        $downloadUrl = "https://github.com/$RepoOwner/$RepoName/releases/download/$TagName/$($file.Name)"
    }
    else {
        $downloadUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/main/File/$($file.Name)"
    }
    
    $toolName = $baseName
    $toolDesc = "Tool program"
    $toolVer = $Version
    $toolCat = "Other"
    
    if ($toolInfo) {
        if ($toolInfo.name) { $toolName = $toolInfo.name }
        if ($toolInfo.description) { $toolDesc = $toolInfo.description }
        if ($toolInfo.version) { $toolVer = $toolInfo.version }
        if ($toolInfo.category) { $toolCat = $toolInfo.category }
    }
    
    $toolData = @{
        fileName    = $file.Name
        name        = $toolName
        description = $toolDesc
        version     = $toolVer
        category    = $toolCat
        fileSize    = $file.Length
        updateDate  = $file.LastWriteTime.ToString("yyyy-MM-dd")
        downloadUrl = $downloadUrl
    }
    $toolsDataArray += $toolData
}

# Read HTML template and inject data
$htmlContent = Get-Content $IndexHtmlPath -Raw -Encoding UTF8

# Convert tools data to JSON
$toolsJson = $toolsDataArray | ConvertTo-Json -Depth 10 -Compress
if ($toolsDataArray.Count -eq 1) {
    $toolsJson = "[$toolsJson]"
}

# Replace toolsData array
$htmlContent = $htmlContent -replace 'const toolsData = \[.*?\];', "const toolsData = $toolsJson;"

# Update year
$currentYear = Get-Date -Format "yyyy"
$htmlContent = $htmlContent -replace [regex]::Escape("2024"), $currentYear

# Write updated HTML
[System.IO.File]::WriteAllText($IndexHtmlPath, $htmlContent, [System.Text.Encoding]::UTF8)
Write-OK "Updated index.html"

# Display tool list
Write-Host ""
Write-Host "  -----------------------------------------" -ForegroundColor DarkGray
Write-Host "  Tool List:" -ForegroundColor DarkGray
Write-Host "  -----------------------------------------" -ForegroundColor DarkGray
foreach ($tool in $toolsDataArray) {
    Write-Host "    * " -ForegroundColor Cyan -NoNewline
    Write-Host "$($tool.name) " -ForegroundColor White -NoNewline
    Write-Host "v$($tool.version)" -ForegroundColor DarkGray
}

# Step 7: Git operations
Write-Host ""
Write-Step "7/7" "Pushing to GitHub..."

Set-Location $ScriptDir

# Ensure branch is main
$currentBranch = git branch --show-current 2>$null
if ($currentBranch -ne "main") {
    git branch -M main 2>$null
}

git add .
git commit -m "Release $Version - $Message"
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-OK "Pushed to GitHub"
}
else {
    Write-Err "Push failed, check network or permissions"
}

# Complete
Write-Host ""
Write-Host "  =========================================" -ForegroundColor Green
Write-Host "          Publish Complete!                " -ForegroundColor Green
Write-Host "  =========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  GitHub Releases:" -ForegroundColor Yellow
Write-Host "     https://github.com/$RepoOwner/$RepoName/releases" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Download Page (after enabling GitHub Pages):" -ForegroundColor Yellow
Write-Host "     https://$RepoOwner.github.io/$RepoName/" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Tip: Go to GitHub Repository Settings > Pages" -ForegroundColor DarkGray
Write-Host "       Select Source: Deploy from a branch" -ForegroundColor DarkGray
Write-Host "       Select Branch: main, Folder: /docs" -ForegroundColor DarkGray
Write-Host ""
