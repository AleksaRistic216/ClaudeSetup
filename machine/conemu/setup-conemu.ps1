<#
.SYNOPSIS
    Installs ConEmu (if missing) and applies custom keyboard/display settings.
.DESCRIPTION
    Run from the ClaudeSetup /setup skill on Windows. This script:
      1. Installs ConEmu via winget if not already present
      2. Patches ConEmu.xml with custom shortcuts and display settings
    Requires: winget, JetBrains Mono font installed on the system.
#>

param(
    [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"

# --- Locate or install ConEmu ---
$conemuPaths = @(
    "$env:ProgramFiles\ConEmu\ConEmu.xml",
    "${env:ProgramFiles(x86)}\ConEmu\ConEmu.xml",
    "$env:APPDATA\ConEmu.xml",
    "$env:USERPROFILE\ConEmu.xml"
)

$configPath = $conemuPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $configPath -and -not $SkipInstall) {
    Write-Host "ConEmu not found. Installing via winget..." -ForegroundColor Yellow
    winget install Maximus5.ConEmu --accept-package-agreements --accept-source-agreements
    # Re-check after install
    $configPath = $conemuPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
}

if (-not $configPath) {
    Write-Error "ConEmu.xml not found. Install ConEmu first, launch it once to generate config, then re-run this script."
    exit 1
}

Write-Host "Found ConEmu config: $configPath" -ForegroundColor Green

# --- Apply settings via find-and-replace ---
# Each entry: [setting name, attribute type, old regex pattern, new value]
# We match broadly so the script works even if defaults differ across ConEmu versions.

$patches = @{
    # Font: JetBrains Mono
    'FontName'             = @{ type = 'string'; value = 'JetBrains Mono' }

    # Zoom: Ctrl+Shift+= (larger), Ctrl+- (smaller)
    'FontLargerKey'        = @{ type = 'dword'; value = '001011bb' }
    'FontSmallerKey'       = @{ type = 'dword'; value = '000011bd' }

    # Split panels: Ctrl+T (horizontal), Ctrl+Alt+T (vertical)
    'Multi.NewSplitH'      = @{ type = 'dword'; value = '00001154' }
    'Multi.NewSplitV'      = @{ type = 'dword'; value = '00121154' }

    # Resize panels: Alt+J/K/L/;
    'Multi.SplitSizeHL'    = @{ type = 'dword'; value = '0000124a' }  # Alt+J = left
    'Multi.SplitSizeVU'    = @{ type = 'dword'; value = '0000124b' }  # Alt+K = up
    'Multi.SplitSizeHR'    = @{ type = 'dword'; value = '0000124c' }  # Alt+L = right
    'Multi.SplitSizeVD'    = @{ type = 'dword'; value = '000012ba' }  # Alt+; = down

    # Navigate panels: Ctrl+Alt+PgUp/PgDn/Home/End
    'Multi.SplitFocusU'    = @{ type = 'dword'; value = '00121121' }  # Ctrl+Alt+PgUp
    'Multi.SplitFocusD'    = @{ type = 'dword'; value = '00121122' }  # Ctrl+Alt+PgDn
    'Multi.SplitFocusL'    = @{ type = 'dword'; value = '00121124' }  # Ctrl+Alt+Home
    'Multi.SplitFocusR'    = @{ type = 'dword'; value = '00121123' }  # Ctrl+Alt+End

    # Close panel: Ctrl+W
    'Multi.Close'          = @{ type = 'dword'; value = '00001157' }

    # Inactive panel fade (stronger dim effect)
    'FadeInactive'         = @{ type = 'hex'; value = '01' }
    'FadeInactiveHigh'     = @{ type = 'hex'; value = '90' }
}

$content = Get-Content $configPath -Raw
$changeCount = 0

foreach ($name in $patches.Keys) {
    $p = $patches[$name]
    $pattern = "name=""$name"" type=""$($p.type)"" data=""[^""]*"""
    $replacement = "name=""$name"" type=""$($p.type)"" data=""$($p.value)"""

    if ($content -match [regex]::Escape("name=""$name""")) {
        $content = [regex]::Replace($content, $pattern, $replacement)
        $changeCount++
        Write-Host "  Patched: $name = $($p.value)" -ForegroundColor Cyan
    } else {
        Write-Host "  Skipped (not found): $name" -ForegroundColor DarkYellow
    }
}

Set-Content $configPath -Value $content -NoNewline
Write-Host "`nApplied $changeCount settings to $configPath" -ForegroundColor Green
Write-Host "Restart ConEmu for changes to take effect." -ForegroundColor Yellow
