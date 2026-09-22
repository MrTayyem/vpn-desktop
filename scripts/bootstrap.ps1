<#
.SYNOPSIS
  One-time dev environment setup for building TayyemVPN Desktop on Windows.
  Run from an elevated PowerShell (Run as Administrator).

  Installs, if missing: Rust (via rustup), Node.js LTS, Visual Studio Build Tools
  (C++ workload, required by Tauri's linker), and the community OpenVPN client.
  Also downloads WinDivert and places it in resources/windivert/ for per-app split
  tunneling.

  Safe to re-run \u2014 every step checks whether it's already done first.
#>

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

function Test-Command($name) {
  return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

Write-Host "== TayyemVPN Desktop \u2014 dev environment setup ==" -ForegroundColor Cyan

if (-not (Test-Command 'winget')) {
  Write-Host "winget not found. Install 'App Installer' from the Microsoft Store, then re-run this script." -ForegroundColor Red
  exit 1
}

# --- Rust ---
if (-not (Test-Command 'cargo')) {
  Write-Host "Installing Rust (rustup)..." -ForegroundColor Yellow
  winget install --id Rustlang.Rustup -e --accept-source-agreements --accept-package-agreements
  Write-Host "Rust installed. Close and reopen this terminal, then re-run this script to continue." -ForegroundColor Yellow
  exit 0
} else {
  Write-Host "Rust: found" -ForegroundColor Green
}

# --- Node.js ---
if (-not (Test-Command 'node')) {
  Write-Host "Installing Node.js LTS..." -ForegroundColor Yellow
  winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements
  Write-Host "Node installed. Close and reopen this terminal, then re-run this script to continue." -ForegroundColor Yellow
  exit 0
} else {
  Write-Host "Node.js: found" -ForegroundColor Green
}

# --- Visual Studio Build Tools (C++ workload \u2014 needed by Tauri's Rust linker) ---
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$hasCppTools = $false
if (Test-Path $vsWhere) {
  $installed = & $vsWhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
  $hasCppTools = [bool]$installed
}
if (-not $hasCppTools) {
  Write-Host "Installing Visual Studio Build Tools (C++ workload) \u2014 this is the slow one, several GB..." -ForegroundColor Yellow
  winget install --id Microsoft.VisualStudio.2022.BuildTools -e --accept-source-agreements --accept-package-agreements --override "--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --quiet --wait"
} else {
  Write-Host "VS Build Tools (C++ workload): found" -ForegroundColor Green
}

# --- OpenVPN community client (needed at RUNTIME, not just build time) ---
$openvpnPath = "C:\Program Files\OpenVPN\bin\openvpn.exe"
if (-not (Test-Path $openvpnPath)) {
  Write-Host "Installing OpenVPN (community client)..." -ForegroundColor Yellow
  winget install --id OpenVPNTechnologies.OpenVPN -e --accept-source-agreements --accept-package-agreements
} else {
  Write-Host "OpenVPN: found" -ForegroundColor Green
}

# --- WinDivert (for per-app split tunneling) ---
$windivertDir = Join-Path $root "resources\windivert"
$dllPath = Join-Path $windivertDir "WinDivert.dll"
if (-not (Test-Path $dllPath)) {
  Write-Host "Downloading WinDivert..." -ForegroundColor Yellow
  New-Item -ItemType Directory -Force -Path $windivertDir | Out-Null
  $release = Invoke-RestMethod -Uri "https://api.github.com/repos/basil00/WinDivert/releases/latest"
  $asset = $release.assets | Where-Object { $_.name -match '\.zip$' } | Select-Object -First 1
  if (-not $asset) {
    Write-Host "Could not find a WinDivert release zip \u2014 grab it manually, see resources/windivert/README.md" -ForegroundColor Red
  } else {
    $zipPath = Join-Path $env:TEMP "windivert.zip"
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath
    $extractDir = Join-Path $env:TEMP "windivert-extract"
    Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
    $x64Dir = Get-ChildItem -Path $extractDir -Recurse -Directory -Filter "x64" | Select-Object -First 1
    if ($x64Dir) {
      Copy-Item (Join-Path $x64Dir.FullName "WinDivert.dll") $windivertDir -Force
      Copy-Item (Join-Path $x64Dir.FullName "WinDivert64.sys") $windivertDir -Force
      Write-Host "WinDivert installed to resources/windivert/" -ForegroundColor Green
    } else {
      Write-Host "Unexpected WinDivert zip layout \u2014 grab it manually, see resources/windivert/README.md" -ForegroundColor Red
    }
    Remove-Item $zipPath, $extractDir -Recurse -Force -ErrorAction SilentlyContinue
  }
} else {
  Write-Host "WinDivert: found" -ForegroundColor Green
}

Write-Host ""
Write-Host "== Setup complete ==" -ForegroundColor Cyan
Write-Host "Next: cd '$root'; npm install; npm run tauri dev"
