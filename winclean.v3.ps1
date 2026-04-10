# ==============================================================================
# WINDOWS CLEANUP & DRIVER LOCK SCRIPT - v3 (Interactive Menu)
# ==============================================================================

# Self-Elevate to Admin with Bypass
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList "-ExecutionPolicy Bypass -NoProfile $arguments"
    exit
}

# ------------------------------------------------------------------------------
function Run-Phase1 {
    Write-Host "`n--- Phase 1: Removing Provisioned Packages ---" -ForegroundColor Cyan
    Get-AppxProvisionedPackage -Online | ForEach-Object {
        Write-Host "Removing Provisioned: $($_.DisplayName)" -ForegroundColor Yellow
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
    }
    Write-Host "Done." -ForegroundColor Green
}

function Run-Phase2 {
    Write-Host "`n--- Phase 2: Removing Installed User Apps ---" -ForegroundColor Cyan
    Get-AppxPackage -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
    Write-Host "Done." -ForegroundColor Green
}

function Run-Phase3 {
    Write-Host "`n--- Phase 3: Stripping Edge & OneDrive ---" -ForegroundColor Cyan
    # Edge Removal
    $EdgePath = (Get-ChildItem "C:\Program Files (x86)\Microsoft\Edge\Application" -Include "setup.exe" -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
    if ($EdgePath) {
        Write-Host "Uninstalling Edge..." -ForegroundColor Yellow
        Start-Process $EdgePath -ArgumentList "--uninstall --system-level --verbose-logging --force-uninstall" -Wait
    } else {
        Write-Host "Edge setup not found, skipping." -ForegroundColor DarkGray
    }
    # OneDrive Removal
    taskkill /f /im OneDrive.exe 2>$null
    $OSBit = if ([Environment]::Is64BitOperatingSystem) { "SysWOW64" } else { "System32" }
    $ODSetup = "$env:SystemRoot\$OSBit\OneDriveSetup.exe"
    if (Test-Path $ODSetup) {
        Write-Host "Uninstalling OneDrive..." -ForegroundColor Yellow
        Start-Process $ODSetup -ArgumentList "/uninstall" -Wait
    } else {
        Write-Host "OneDrive setup not found, skipping." -ForegroundColor DarkGray
    }
    Write-Host "Done." -ForegroundColor Green
}

function Run-Phase4 {
    Write-Host "`n--- Phase 4: Disabling Telemetry ---" -ForegroundColor Cyan
    Stop-Service -Name "DiagTrack", "dmwappushservice" -ErrorAction SilentlyContinue
    Set-Service -Name "DiagTrack", "dmwappushservice" -StartupType Disabled
    $RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    if (-not (Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }
    Set-ItemProperty -Path $RegPath -Name "AllowTelemetry" -Value 0
    Write-Host "Done." -ForegroundColor Green
}

function Run-Phase5 {
    Write-Host "`n--- Phase 5: Disabling Automatic Driver Updates ---" -ForegroundColor Cyan
    $UpdatePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    if (-not (Test-Path $UpdatePath)) { New-Item -Path $UpdatePath -Force | Out-Null }
    Set-ItemProperty -Path $UpdatePath -Name "ExcludeWUDriversInQualityUpdate" -Value 1
    $ConfigPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching"
    Set-ItemProperty -Path $ConfigPath -Name "SearchOrderConfig" -Value 0
    Write-Host "Done. Drivers are now locked." -ForegroundColor Green
}

function Run-Phase6 {
    Write-Host "`n--- Phase 6: Deep Cleaning App Folders ---" -ForegroundColor Cyan
    $Targets = @("C:\Program Files\WindowsApps", "C:\ProgramData\Microsoft\Windows\AppRepository")
    foreach ($Path in $Targets) {
        if (Test-Path $Path) {
            Write-Host "Cleaning: $Path" -ForegroundColor Yellow
            takeown /f $Path /r /d y | Out-Null
            icacls $Path /grant administrators:F /t | Out-Null
            Get-ChildItem $Path -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
    Write-Host "Done." -ForegroundColor Green
}

function Run-AllPhases {
    Run-Phase1
    Run-Phase2
    Run-Phase3
    Run-Phase4
    Run-Phase5
    Run-Phase6
}

# ------------------------------------------------------------------------------
# APP INSTALLER (winget)
# ------------------------------------------------------------------------------
$AppList = [ordered]@{
    "1" = @{ Name = "Google Chrome";    Id = "Google.Chrome" }
    "2" = @{ Name = "Mozilla Firefox";  Id = "Mozilla.Firefox" }
    "3" = @{ Name = "Brave Browser";    Id = "Brave.Brave" }
    "4" = @{ Name = "7-Zip";            Id = "7zip.7zip" }
    "5" = @{ Name = "VLC Media Player"; Id = "VideoLAN.VLC" }
    "6" = @{ Name = "Notepad++";        Id = "Notepad++.Notepad++" }
    "7" = @{ Name = "VS Code";          Id = "Microsoft.VisualStudioCode" }
    "8" = @{ Name = "PowerToys";        Id = "Microsoft.PowerToys" }
    "9" = @{ Name = "Git";              Id = "Git.Git" }
}

function Install-App($entry) {
    Write-Host "`nInstalling $($entry.Name)..." -ForegroundColor Cyan
    winget install --id $entry.Id --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$($entry.Name) installed successfully." -ForegroundColor Green
    } else {
        Write-Host "Install may have failed or app is already installed (exit code $LASTEXITCODE)." -ForegroundColor Yellow
    }
}

function Show-AppMenu {
    do {
        Clear-Host
        Write-Host "============================================" -ForegroundColor White
        Write-Host "   WINCLEAN v3 - Install Apps" -ForegroundColor White
        Write-Host "============================================" -ForegroundColor White
        foreach ($key in $AppList.Keys) {
            Write-Host "  $key  $($AppList[$key].Name)" -ForegroundColor Yellow
        }
        Write-Host "  A  Install ALL" -ForegroundColor Cyan
        Write-Host "  B  Back to main menu" -ForegroundColor DarkGray
        Write-Host "============================================" -ForegroundColor White

        $pick = Read-Host "`nEnter option"

        switch ($pick.Trim().ToUpper()) {
            "A" {
                foreach ($key in $AppList.Keys) { Install-App $AppList[$key] }
                Read-Host "`nAll done. Press Enter to return to menu"
            }
            "B" { return }
            default {
                if ($AppList.Contains($pick.Trim())) {
                    Install-App $AppList[$pick.Trim()]
                    Read-Host "`nPress Enter to return to app menu"
                } else {
                    Write-Host "Invalid option." -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
        }
    } while ($true)
}

# ------------------------------------------------------------------------------
# MENU LOOP
# ------------------------------------------------------------------------------
do {
    Clear-Host
    Write-Host "============================================" -ForegroundColor White
    Write-Host "   WINCLEAN v3 - Interactive Menu" -ForegroundColor White
    Write-Host "============================================" -ForegroundColor White
    Write-Host "  1  Remove Provisioned Packages" -ForegroundColor Yellow
    Write-Host "  2  Remove Installed User Apps" -ForegroundColor Yellow
    Write-Host "  3  Strip Edge & OneDrive" -ForegroundColor Yellow
    Write-Host "  4  Disable Telemetry" -ForegroundColor Yellow
    Write-Host "  5  Disable Automatic Driver Updates" -ForegroundColor Yellow
    Write-Host "  6  Deep Clean App Folders" -ForegroundColor Yellow
    Write-Host "  A  Run ALL phases" -ForegroundColor Cyan
    Write-Host "  I  Install Apps" -ForegroundColor Cyan
    Write-Host "  R  Reboot" -ForegroundColor Magenta
    Write-Host "  Q  Quit" -ForegroundColor DarkGray
    Write-Host "============================================" -ForegroundColor White

    $choice = Read-Host "`nEnter option"

    switch ($choice.Trim().ToUpper()) {
        "1" { Run-Phase1; Read-Host "`nPress Enter to return to menu" }
        "2" { Run-Phase2; Read-Host "`nPress Enter to return to menu" }
        "3" { Run-Phase3; Read-Host "`nPress Enter to return to menu" }
        "4" { Run-Phase4; Read-Host "`nPress Enter to return to menu" }
        "5" { Run-Phase5; Read-Host "`nPress Enter to return to menu" }
        "6" { Run-Phase6; Read-Host "`nPress Enter to return to menu" }
        "A" { Run-AllPhases; Read-Host "`nPress Enter to return to menu" }
        "I" { Show-AppMenu }
        "R" { Restart-Computer }
        "Q" { Write-Host "Exiting." -ForegroundColor DarkGray; exit }
        default { Write-Host "Invalid option, try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} while ($true)
