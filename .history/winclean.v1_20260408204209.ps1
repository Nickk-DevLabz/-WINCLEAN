# ==============================================================================
# BARE-MINIMUM WINDOWS CLEANUP SCRIPT
# Action: Removes Provisioned Apps, User Apps, Edge, OneDrive, and Telemetry.
# ==============================================================================

# 1. Elevate permissions for the current session
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as an Administrator!"
    break
}

Write-Host "--- Phase 1: Removing Provisioned Packages (The Master Files) ---" -ForegroundColor Cyan
# This is the fixed command you requested
Get-AppxProvisionedPackage -Online | ForEach-Object {
    $name = $_.DisplayName
    Write-Host "Removing: $name" -ForegroundColor Yellow
    Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
}

Write-Host "--- Phase 2: Removing Installed User Apps ---" -ForegroundColor Cyan
Get-AppxPackage -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue

Write-Host "--- Phase 3: Stripping Microsoft Edge & OneDrive ---" -ForegroundColor Cyan
# Kill Edge
$EdgePath = (Get-ChildItem "C:\Program Files (x86)\Microsoft\Edge\Application" -Include "setup.exe" -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
if ($EdgePath) {
    Start-Process $EdgePath -ArgumentList "--uninstall --system-level --verbose-logging --force-uninstall" -Wait
}

# Kill OneDrive
taskkill /f /im OneDrive.exe -ErrorAction SilentlyContinue
$OSBit = if ([Environment]::Is64BitOperatingSystem) { "SysWOW64" } else { "System32" }
$ODSetup = "$env:SystemRoot\$OSBit\OneDriveSetup.exe"
if (Test-Path $ODSetup) { Start-Process $ODSetup -ArgumentList "/uninstall" -Wait }

Write-Host "--- Phase 4: Disabling Telemetry & Data Collection ---" -ForegroundColor Cyan
# Disable services
Stop-Service -Name "DiagTrack", "dmwappushservice" -ErrorAction SilentlyContinue
Set-Service -Name "DiagTrack", "dmwappushservice" -StartupType Disabled

# Registry Blocks
$RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
if (-not (Test-Path $RegPath)) { New-Item -Path $RegPath -Force }
Set-ItemProperty -Path $RegPath -Name "AllowTelemetry" -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0

Write-Host "--- Phase 5: Deep Cleaning Residual Folders ---" -ForegroundColor Cyan
$Targets = @("C:\Program Files\WindowsApps", "C:\ProgramData\Microsoft\Windows\AppRepository")
foreach ($Path in $Targets) {
    if (Test-Path $Path) {
        takeown /f $Path /r /d y > $null
        icacls $Path /grant administrators:F /t > $null
        Get-ChildItem $Path -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    }
}

Write-Host "CLEANUP COMPLETE. Please restart your computer." -ForegroundColor Green
Pause
