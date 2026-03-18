#Requires -Version 5.1
<#
.SYNOPSIS
    LLMx Prompt Studio installer for Windows.

.DESCRIPTION
    Downloads and runs the NSIS installer from GitHub releases.

.PARAMETER Version
    Specific version to install (e.g. 0.1.0). Defaults to latest.

.EXAMPLE
    irm https://raw.githubusercontent.com/llmx-tech/llmx.prompt-studio/main/install.ps1 | iex
    .\install.ps1 -Version 0.1.0
#>
param(
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"
$AppName = "LLMx Prompt Studio"
$GithubRepo = "llmx-tech/llmx.prompt-studio"

function Write-Info($msg)  { Write-Host "==> $msg" -ForegroundColor Blue }
function Write-Ok($msg)    { Write-Host "==> $msg" -ForegroundColor Green }
function Write-Err($msg)   { Write-Host "Error: $msg" -ForegroundColor Red; exit 1 }

# ── Detect architecture ──────────────────────────────────────────────────

$arch = if ([Environment]::Is64BitOperatingSystem) {
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "aarch64" } else { "x86_64" }
} else {
    Write-Err "32-bit Windows is not supported."
}

# ── Resolve version ──────────────────────────────────────────────────────

if (-not $Version) {
    Write-Info "Fetching latest release..."
    try {
        $release = Invoke-RestMethod "https://api.github.com/repos/$GithubRepo/releases/latest"
        $Version = $release.tag_name -replace '^v', ''
    } catch {
        Write-Err "Could not determine latest version. Pass -Version explicitly."
    }
}

$exeName = "LLMx.Prompt.Studio_${Version}_${arch}-setup.exe"
$downloadUrl = "https://github.com/$GithubRepo/releases/download/v$Version/$exeName"

Write-Info "Installing $AppName v$Version ($arch)..."

# ── Download ─────────────────────────────────────────────────────────────

$tempDir = Join-Path $env:TEMP "llmx-install"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
$exePath = Join-Path $tempDir $exeName

Write-Info "Downloading $exeName..."
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $exePath -UseBasicParsing
} catch {
    Write-Err "Download failed. Check that v$Version exists at: $downloadUrl"
}

# ── Install ──────────────────────────────────────────────────────────────

Write-Info "Running installer..."
Write-Host ""
Write-Host "  NOTE: Windows SmartScreen may show a warning because the app is not code-signed." -ForegroundColor Yellow
Write-Host "  Click 'More info' then 'Run anyway' to proceed." -ForegroundColor Yellow
Write-Host ""

Start-Process -FilePath $exePath -Wait

# ── Cleanup ──────────────────────────────────────────────────────────────

Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue

Write-Ok "$AppName v$Version installed successfully!"
Write-Host ""
Write-Host "  Find it in the Start Menu or run from the install directory."
Write-Host ""
