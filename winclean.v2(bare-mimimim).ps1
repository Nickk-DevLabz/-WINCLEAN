# ==============================================================================
# BARE-MINIMUM WINDOWS CLEANUP & DRIVER LOCK SCRIPT
# ==============================================================================

# 1. Self-Elevate to Admin with Bypass
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList "-ExecutionPolicy Bypass -NoProfile $arguments"
    exit
}

Write-Host "--- Phase 1: Removing Provisioned Packages ---" -ForegroundColor Cyan
Get-AppxProvisionedPackage -Online | ForEach-Object {
    Write-Host "Removing Provisioned: $($_.DisplayName)" -ForegroundColor Yellow
    Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
}

Write-Host "--- Phase 2: Removing Installed User Apps ---" -ForegroundColor Cyan
Get-AppxPackage -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue

Write-Host "--- Phase 3: Stripping Edge & OneDrive ---" -ForegroundColor Cyan
# Edge Removal
$EdgePath = (Get-ChildItem "C:\Program Files (x86)\Microsoft\Edge\Application" -Include "setup.exe" -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
if ($EdgePath) { Start-Process $EdgePath -ArgumentList "--uninstall --system-level --verbose-logging --force-uninstall" -Wait }
# OneDrive Removal
taskkill /f /im OneDrive.exe -ErrorAction SilentlyContinue
$OSBit = if ([Environment]::Is64BitOperatingSystem) { "SysWOW64" } else { "System32" }
$ODSetup = "$env:SystemRoot\$OSBit\OneDriveSetup.exe"
if (Test-Path $ODSetup) { Start-Process $ODSetup -ArgumentList "/uninstall" -Wait }

Write-Host "--- Phase 4: Disabling Telemetry ---" -ForegroundColor Cyan
Stop-Service -Name "DiagTrack", "dmwappushservice" -ErrorAction SilentlyContinue
Set-Service -Name "DiagTrack", "dmwappushservice" -StartupType Disabled
$RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
if (-not (Test-Path $RegPath)) { New-Item -Path $RegPath -Force }
Set-ItemProperty -Path $RegPath -Name "AllowTelemetry" -Value 0

Write-Host "--- Phase 5: DISABLING AUTOMATIC DRIVER UPDATES ---" -ForegroundColor Green
# This prevents Windows Update from touching your hardware drivers
$UpdatePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
if (-not (Test-Path $UpdatePath)) { New-Item -Path $UpdatePath -Force }
Set-ItemProperty -Path $UpdatePath -Name "ExcludeWUDriversInQualityUpdate" -Value 1

# Additional Hardware Driver Search block
$ConfigPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching"
Set-ItemProperty -Path $ConfigPath -Name "SearchOrderConfig" -Value 0

Write-Host "--- Phase 6: Deep Cleaning Folders ---" -ForegroundColor Cyan
$Targets = @("C:\Program Files\WindowsApps", "C:\ProgramData\Microsoft\Windows\AppRepository")
foreach ($Path in $Targets) {
    if (Test-Path $Path) {
        takeown /f $Path /r /d y > $null
        icacls $Path /grant administrators:F /t > $null
        Get-ChildItem $Path -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    }
}

Write-Host "--- CLEANUP COMPLETE ---" -ForegroundColor Cyan
Write-Host "Drivers are now locked. Windows will no longer update them automatically." -ForegroundColor Yellow
Read-Host "Press Enter to Reboot now..."
Restart-Computer
