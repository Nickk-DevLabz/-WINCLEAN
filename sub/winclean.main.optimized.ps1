# ==============================================================================
# WINCLEAN PRO v5.1 - OPTIMIZED TECHNICIAN SUITE
# Refined STAR Execution | UI Liveness | Robust Logging
# ==============================================================================

# Self-Elevate to Admin with Bypass
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

# Set up console for debugging visibility
$host.UI.RawUI.WindowTitle = "WinClean Pro v5.1 - Engine Monitor"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  WinClean Pro v5.1 - Booting Engine..." -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Capture script environment
[string]$Script:ScriptDir = $PSScriptRoot
if (-not $Script:ScriptDir) { $Script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }

# ==============================================================================
# LOGGING ENGINE
# ==============================================================================
$Global:LogFile = Join-Path $Script:ScriptDir "WinClean_Audit.log"

function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $Stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Entry = "[$Stamp] [$Type] $Message"
    Write-Host $Entry -ForegroundColor $(switch($Type){"ERROR"{"Red"};"WARN"{"Yellow"};"START"{"Cyan"};Default{"Gray"}})
    try {
        # Ensure directory exists before logging
        $logDir = Split-Path $Global:LogFile
        if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
        $Entry | Out-File -FilePath $Global:LogFile -Append -Encoding UTF8
    } catch {}
}
Write-Log "WinClean Pro Session Initialized." "START"

# ==============================================================================
# GLOBAL STATE
# ==============================================================================
$Global:SelectedApps = New-Object System.Collections.Generic.HashSet[string]
$Global:AllInstalledApps = @()
$Script:SearchIsPlaceholder = $true

# ==============================================================================
# MAIN FORM UI
# ==============================================================================
$Form = New-Object System.Windows.Forms.Form
$Form.Text            = "WinClean Pro v5.1 - Professional Technician Suite"
$Form.Size            = New-Object System.Drawing.Size(840, 940)
$Form.StartPosition   = "CenterScreen"
$Form.BackColor       = [System.Drawing.Color]::FromArgb(25, 25, 25)
$Form.ForeColor       = [System.Drawing.Color]::White
$Form.Font            = New-Object System.Drawing.Font("Segoe UI", 10)
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox     = $false

# UI Header
$pnlTop = New-Object System.Windows.Forms.Panel -Property @{ Dock="Top"; Height=58; BackColor=[System.Drawing.Color]::FromArgb(42, 42, 42) }
$Form.Controls.Add($pnlTop)

$btnSave = New-Object System.Windows.Forms.Button -Property @{ Text="SAVE PROFILE"; Location="20,12"; Size="145,33"; FlatStyle="Flat" }
$btnSave.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$pnlTop.Controls.Add($btnSave)

$btnLoad = New-Object System.Windows.Forms.Button -Property @{ Text="LOAD PROFILE"; Location="175,12"; Size="145,33"; FlatStyle="Flat" }
$btnLoad.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$pnlTop.Controls.Add($btnLoad)

$lblProfileStatus = New-Object System.Windows.Forms.Label -Property @{ Text="Session Active"; Location="335,20"; AutoSize=$true; ForeColor=[System.Drawing.Color]::Gray }
$pnlTop.Controls.Add($lblProfileStatus)

$TabCtrl = New-Object System.Windows.Forms.TabControl -Property @{ Location="20,68"; Size="785,820" }
$Form.Controls.Add($TabCtrl)

# --- TAB 1: OS CLEANUP ---
$Tab1 = New-Object System.Windows.Forms.TabPage -Property @{ Text="  OS Cleanup  "; BackColor=[System.Drawing.Color]::FromArgb(32, 32, 32) }
$TabCtrl.TabPages.Add($Tab1)

$chkUnlock = New-Object System.Windows.Forms.CheckBox -Property @{ Text="Unlock Permanent System Apps (Registry Hijack)"; Location="20,15"; AutoSize=$true; ForeColor=[System.Drawing.Color]::OrangeRed }
$Tab1.Controls.Add($chkUnlock)

$chkShell = New-Object System.Windows.Forms.CheckBox -Property @{ Text="Auto-Restart Explorer & Re-register Shell"; Location="20,45"; AutoSize=$true; Checked=$true }
$Tab1.Controls.Add($chkShell)

$lblFilter = New-Object System.Windows.Forms.Label -Property @{ Text="Category:"; Location="20,87"; AutoSize=$true; ForeColor=[System.Drawing.Color]::Gray }
$Tab1.Controls.Add($lblFilter)

$cmbCategory = New-Object System.Windows.Forms.ComboBox -Property @{ Location="100,83"; Size="210,28"; DropDownStyle="DropDownList"; BackColor=[System.Drawing.Color]::FromArgb(48, 48, 48); ForeColor=[System.Drawing.Color]::White }
$cmbCategory.Items.AddRange(@("All", "3rd Party", "Windows/System", "System Protected"))
$cmbCategory.SelectedIndex = 0
$Tab1.Controls.Add($cmbCategory)

$txtSearch = New-Object System.Windows.Forms.TextBox -Property @{ Location="320,83"; Size="440,28"; BackColor=[System.Drawing.Color]::FromArgb(48, 48, 48); ForeColor=[System.Drawing.Color]::Gray; BorderStyle="FixedSingle"; Text="Search installed apps..." }
$Tab1.Controls.Add($txtSearch)

$AppList = New-Object System.Windows.Forms.CheckedListBox -Property @{ Location="20,118"; Size="740,440"; BackColor=[System.Drawing.Color]::FromArgb(38, 38, 38); ForeColor=[System.Drawing.Color]::White; BorderStyle="None"; CheckOnClick=$true }
$Tab1.Controls.Add($AppList)

$btnSelAll = New-Object System.Windows.Forms.Button -Property @{ Text="Select Visible"; Location="20,568"; Size="115,33"; FlatStyle="Flat" }
$Tab1.Controls.Add($btnSelAll)

$btnRefresh = New-Object System.Windows.Forms.Button -Property @{ Text="Refresh Inventory"; Location="145,568"; Size="130,33"; FlatStyle="Flat" }
$Tab1.Controls.Add($btnRefresh)

$lblAppCount = New-Object System.Windows.Forms.Label -Property @{ Text="Scanning..."; Location="290,577"; AutoSize=$true; ForeColor=[System.Drawing.Color]::Gray }
$Tab1.Controls.Add($lblAppCount)

$btnRunCleanup = New-Object System.Windows.Forms.Button -Property @{ Text="EXECUTE STAR CLEANUP"; Location="20,615"; Size="740,55"; BackColor=[System.Drawing.Color]::FromArgb(180, 0, 0); FlatStyle="Flat"; Font=New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold) }
$Tab1.Controls.Add($btnRunCleanup)

# --- TAB 2: INSTALL APPS ---
$Tab2 = New-Object System.Windows.Forms.TabPage -Property @{ Text="  Install Apps  "; BackColor=[System.Drawing.Color]::FromArgb(32, 32, 32) }
$TabCtrl.TabPages.Add($Tab2)

$AppInstList = New-Object System.Windows.Forms.CheckedListBox -Property @{ Location="20,48"; Size="740,520"; BackColor=[System.Drawing.Color]::FromArgb(38, 38, 38); ForeColor=[System.Drawing.Color]::White; BorderStyle="None"; CheckOnClick=$true }
$Tab2.Controls.Add($AppInstList)

$btnInstall = New-Object System.Windows.Forms.Button -Property @{ Text="RUN STAR INSTALLER (WINGET)"; Location="20,608"; Size="740,55"; BackColor=[System.Drawing.Color]::FromArgb(0, 110, 0); FlatStyle="Flat"; Font=New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold) }
$Tab2.Controls.Add($btnInstall)

# --- TAB 3: SYSTEM TWEAKS ---
$Tab3 = New-Object System.Windows.Forms.TabPage -Property @{ Text="  System Tweaks  "; BackColor=[System.Drawing.Color]::FromArgb(32, 32, 32) }
$TabCtrl.TabPages.Add($Tab3)

$gbPerfUI = New-Object System.Windows.Forms.GroupBox -Property @{ Text="Optimization"; Location="20,15"; Size="740,150"; ForeColor=[System.Drawing.Color]::DeepSkyBlue }
$Tab3.Controls.Add($gbPerfUI)

$chkCortana = New-Object System.Windows.Forms.CheckBox -Property @{ Text="Disable Cortana / Search Indexing"; Location="15,30"; AutoSize=$true }
$gbPerfUI.Controls.Add($chkCortana)

$chkHighPerf = New-Object System.Windows.Forms.CheckBox -Property @{ Text="Force Ultimate Performance Power Plan"; Location="15,60"; AutoSize=$true; ForeColor=[System.Drawing.Color]::OrangeRed }
$gbPerfUI.Controls.Add($chkHighPerf)

$chkGameBar = New-Object System.Windows.Forms.CheckBox -Property @{ Text="Disable Xbox Game DVR Services"; Location="15,90"; AutoSize=$true }
$gbPerfUI.Controls.Add($chkGameBar)

$chkLongPaths = New-Object System.Windows.Forms.CheckBox -Property @{ Text="Enable NTFS Long Path Support"; Location="15,120"; AutoSize=$true }
$gbPerfUI.Controls.Add($chkLongPaths)

$gbMaint = New-Object System.Windows.Forms.GroupBox -Property @{ Text="Maintenance Operations"; Location="20,175"; Size="740,120"; ForeColor=[System.Drawing.Color]::DeepSkyBlue }
$Tab3.Controls.Add($gbMaint)

$btnSFC = New-Object System.Windows.Forms.Button -Property @{ Text="SFC SCANNOW"; Location="15,30"; Size="220,35"; FlatStyle="Flat" }
$gbMaint.Controls.Add($btnSFC)

$btnDISM = New-Object System.Windows.Forms.Button -Property @{ Text="DISM RESTORE HEALTH"; Location="250,30"; Size="220,35"; FlatStyle="Flat" }
$gbMaint.Controls.Add($btnDISM)

$btnCleanMgr = New-Object System.Windows.Forms.Button -Property @{ Text="CLEAN TEMP/RECYCLE"; Location="485,30"; Size="220,35"; FlatStyle="Flat"; BackColor=[System.Drawing.Color]::FromArgb(60, 60, 60) }
$gbMaint.Controls.Add($btnCleanMgr)

$btnRunTweaks = New-Object System.Windows.Forms.Button -Property @{ Text="APPLY SELECTED STAR TWEAKS"; Location="20,660"; Size="740,55"; BackColor=[System.Drawing.Color]::FromArgb(0, 100, 160); FlatStyle="Flat"; Font=New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold) }
$Tab3.Controls.Add($btnRunTweaks)

# --- TAB 4: DIAGNOSTICS ---
$Tab4 = New-Object System.Windows.Forms.TabPage -Property @{ Text="  Diagnostics  "; BackColor=[System.Drawing.Color]::FromArgb(32, 32, 32) }
$TabCtrl.TabPages.Add($Tab4)

$btnDiag = New-Object System.Windows.Forms.Button -Property @{ Text="GENERATE HARDWARE HEALTH REPORT"; Location="20,15"; Size="740,50"; BackColor=[System.Drawing.Color]::FromArgb(0, 118, 118); FlatStyle="Flat"; Font=New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold) }
$Tab4.Controls.Add($btnDiag)

$txtDiag = New-Object System.Windows.Forms.TextBox -Property @{ Location="20,80"; Size="740,620"; Multiline=$true; ReadOnly=$true; ScrollBars="Vertical"; BackColor=[System.Drawing.Color]::Black; ForeColor=[System.Drawing.Color]::Lime; Font=New-Object System.Drawing.Font("Consolas", 10); BorderStyle="None" }
$Tab4.Controls.Add($txtDiag)

# --- TAB 5: TOOLS ---
$Tab5 = New-Object System.Windows.Forms.TabPage -Property @{ Text="  External Tools  "; BackColor=[System.Drawing.Color]::FromArgb(32, 32, 32) }
$TabCtrl.TabPages.Add($Tab5)

$btnWinutil = New-Object System.Windows.Forms.Button -Property @{ Text="OPEN CHRIS TITUS WINUTIL"; Location="20,30"; Size="740,60"; BackColor=[System.Drawing.Color]::FromArgb(0, 100, 160); FlatStyle="Flat"; Font=New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold) }
$Tab5.Controls.Add($btnWinutil)

# ==============================================================================
# STAR EXECUTION ENGINE
# ==============================================================================

function Execute-STARAction {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][scriptblock]$Situation,
        [Parameter(Mandatory=$true)][scriptblock]$Task,
        [Parameter(Mandatory=$true)][scriptblock]$Action,
        [Parameter(Mandatory=$true)][scriptblock]$Result
    )
    
    # S - Situation: Preparation
    Write-Log "STAR Cycle Initiated: $Name" "START"
    &$Situation
    $Form.Refresh()
    [System.Windows.Forms.Application]::DoEvents()

    try {
        # T - Task: Validation & Data Gathering
        $Context = &$Task
        if ($null -eq $Context -or $Context.Continue -eq $false) {
            Write-Log "STAR Cycle Aborted by User or Validation Error ($Name)" "WARN"
            return
        }

        # A - Action: High-Level Execution
        Write-Log "Executing Action phase for $Name..."
        &$Action $Context

        # R - Result: Outcome and Cleanup
        &$Result $Context
        Write-Log "STAR Cycle Successfully Completed: $Name"
    } catch {
        $errMsg = $_.Exception.Message
        Write-Log "CRITICAL STAR FAILURE ($Name): $errMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("STAR Engine Error in $Name`:`n`n$errMsg", "Execution Error", "OK", "Error")
    }
}

# ==============================================================================
# CORE LOGIC FUNCTIONS
# ==============================================================================

function Reload-AppList {
    $lblAppCount.Text = "Scanning System..."
    $AppList.Enabled = $false
    $Form.Refresh()
    [System.Windows.Forms.Application]::DoEvents()

    try {
        $pkgs = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        $Global:AllInstalledApps = $(foreach ($p in $pkgs) {
            $cat = "3rd Party"
            if ($p.SignatureKind -eq "System" -or $p.IsFramework) {
                $cat = "System Protected"
            } elseif ($p.Publisher -match "Microsoft") {
                $cat = "Windows/System"
            }
            
            [PSCustomObject]@{
                Name     = $p.Name
                Category = $cat
                Tag      = "[$($cat)] $($p.Name)"
            }
            # Keep UI responsive during large inventory scans
            if ($pkgs.IndexOf($p) % 10 -eq 0) { [System.Windows.Forms.Application]::DoEvents() }
        }) | Sort-Object Category, Name
        
        Apply-AppFilter
    } catch {
        Write-Log "Failed to load Appx inventory: $($_.Exception.Message)" "ERROR"
    }
}

function Apply-AppFilter {
    $filterText = if (-not $Script:SearchIsPlaceholder) { $txtSearch.Text } else { "" }
    $filterCat  = $cmbCategory.SelectedItem
    
    $AppList.Enabled = $false
    $AppList.Items.Clear()
    
    foreach ($app in $Global:AllInstalledApps) {
        $matchText = ($filterText -eq "" -or $app.Name -like "*$filterText*")
        $matchCat  = ($filterCat -eq "All" -or $app.Category -eq $filterCat)
        
        if ($matchText -and $matchCat) {
            $idx = $AppList.Items.Add($app.Tag)
            if ($Global:SelectedApps.Contains($app.Name)) {
                $AppList.SetItemChecked($idx, $true)
            }
        }
    }
    
    $AppList.Enabled = $true
    $lblAppCount.Text = "$($AppList.Items.Count) apps matched filter"
}

# ==============================================================================
# OS CLEANUP HANDLERS
# ==============================================================================

$AppList.Add_ItemCheck({
    param($s, $e)
    if ($AppList.Enabled) {
        $displayString = $AppList.Items[$e.Index]
        $rawName = $displayString -replace '^\[.*?\]\s*', ''
        if ($e.NewValue -eq "Checked") {
            [void]$Global:SelectedApps.Add($rawName)
        } else {
            [void]$Global:SelectedApps.Remove($rawName)
        }
    }
})

$txtSearch.Add_GotFocus({
    if ($Script:SearchIsPlaceholder) {
        $Script:SearchIsPlaceholder = $false
        $txtSearch.Text = ""; $txtSearch.ForeColor = [System.Drawing.Color]::White
    }
})

$txtSearch.Add_LostFocus({
    if ($txtSearch.Text -eq "") {
        $Script:SearchIsPlaceholder = $true
        $txtSearch.Text = "Search installed apps..."; $txtSearch.ForeColor = [System.Drawing.Color]::Gray
    }
})

$txtSearch.Add_TextChanged({ if (-not $Script:SearchIsPlaceholder) { Apply-AppFilter } })
$cmbCategory.Add_SelectedIndexChanged({ Apply-AppFilter })
$btnRefresh.Add_Click({ Reload-AppList })

$btnSelAll.Add_Click({
    for ($i = 0; $i -lt $AppList.Items.Count; $i++) {
        $AppList.SetItemChecked($i, $true)
        $rawName = $AppList.Items[$i] -replace '^\[.*?\]\s*', ''
        [void]$Global:SelectedApps.Add($rawName)
    }
})

$btnRunCleanup.Add_Click({
    Execute-STARAction -Name "System Bloatware Stripping" `
        -Situation {
            $btnRunCleanup.Enabled = $false
            $btnRunCleanup.Text = "DEBLOATING..."
        } `
        -Task {
            if ($Global:SelectedApps.Count -eq 0) {
                [System.Windows.Forms.MessageBox]::Show("Select target apps first.", "Validation Failed")
                return @{ Continue = $false }
            }
            $confirm = [System.Windows.Forms.MessageBox]::Show("Purge $($Global:SelectedApps.Count) applications?", "Confirm Action", "YesNo", "Warning")
            return @{ Continue = ($confirm -eq "Yes"); Apps = @($Global:SelectedApps); Failures = New-Object System.Collections.Generic.List[string] }
        } `
        -Action {
            param($Ctx)
            if ($chkUnlock.Checked) {
                Write-Log "Overriding Appx Protection in Registry..."
                $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Applications"
                try {
                    Get-ChildItem $regPath -ErrorAction SilentlyContinue | ForEach-Object {
                        Set-ItemProperty -Path $_.PSPath -Name "IsInbox" -Value 0 -ErrorAction SilentlyContinue
                    }
                } catch { Write-Log "Registry override partially failed." "WARN" }
            }

            foreach ($item in $Ctx.Apps) {
                [System.Windows.Forms.Application]::DoEvents()
                $found = $false
                # 1. User/Live Removal
                $pkgs = Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq $item }
                if ($pkgs) {
                    $found = $true
                    foreach ($p in $pkgs) {
                        try { Remove-AppxPackage -Package $p.PackageFullName -ErrorAction Stop } 
                        catch { $Ctx.Failures.Add("User-level fail ($item): $($_.Exception.Message)") }
                    }
                }
                # 2. Provisioned/Image Removal
                $prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $item }
                if ($prov) {
                    $found = $true
                    try { Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction Stop | Out-Null } 
                    catch { $Ctx.Failures.Add("System-level fail ($item): $($_.Exception.Message)") }
                }
            }
            if ($chkShell.Checked) { 
                Write-Log "Restarting Explorer shell..."
                Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue 
            }
        } `
        -Result {
            param($Ctx)
            $btnRunCleanup.Enabled = $true
            $btnRunCleanup.Text = "EXECUTE STAR CLEANUP"
            $Global:SelectedApps.Clear()
            Reload-AppList
            $summary = "Process Finished."
            if ($Ctx.Failures.Count -gt 0) { $summary += "`n`nErrors Encountered:`n" + ($Ctx.Failures -join "`n") }
            [System.Windows.Forms.MessageBox]::Show($summary, "Operation Result")
        }
})

# ==============================================================================
# WINGET INSTALLER HANDLERS
# ==============================================================================

$Global:InstallCatalog = @(
    @{ Name = "Google Chrome"; Id = "Google.Chrome" }
    @{ Name = "7-Zip Utility"; Id = "7zip.7zip" }
    @{ Name = "VLC Media Player"; Id = "VideoLAN.VLC" }
    @{ Name = "Visual Studio Code"; Id = "Microsoft.VisualStudioCode" }
    @{ Name = "Notepad++"; Id = "Notepad++.Notepad++" }
    @{ Name = "Git for Windows"; Id = "Git.Git" }
    @{ Name = "PowerToys"; Id = "Microsoft.PowerToys" }
)
foreach ($a in $Global:InstallCatalog) { [void]$AppInstList.Items.Add($a.Name) }

$btnInstall.Add_Click({
    Execute-STARAction -Name "App Deployment" `
        -Situation {
            $btnInstall.Enabled = $false
            $btnInstall.Text = "DEPLOYING..."
        } `
        -Task {
            $sel = @($AppInstList.CheckedItems)
            if ($sel.Count -eq 0) { return @{ Continue = $false } }
            
            # Pre-flight check for winget
            if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                [System.Windows.Forms.MessageBox]::Show("Winget not found. Please install App Installer.", "Dependency Missing")
                return @{ Continue = $false }
            }
            
            $targets = New-Object System.Collections.Generic.List[PSObject]
            foreach ($name in $sel) {
                $targets.Add(($Global:InstallCatalog | Where-Object { $_.Name -eq $name }))
            }
            return @{ Continue = $true; Targets = $targets; SuccessCount = 0 }
        } `
        -Action {
            param($Ctx)
            foreach ($app in $Ctx.Targets) {
                Write-Log "Processing install: $($app.Name)"
                $proc = Start-Process winget -ArgumentList "install --id $($app.Id) --silent --accept-package-agreements --accept-source-agreements" -NoNewWindow -Wait -PassThru
                # 0x8A150030 = Already installed
                if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq -2145801216) { $Ctx.SuccessCount++ }
                [System.Windows.Forms.Application]::DoEvents()
            }
        } `
        -Result {
            param($Ctx)
            $btnInstall.Enabled = $true
            $btnInstall.Text = "RUN STAR INSTALLER (WINGET)"
            [System.Windows.Forms.MessageBox]::Show("Successfully processed $($Ctx.SuccessCount) of $($Ctx.Targets.Count) apps.", "Deployment Result")
        }
})

# ==============================================================================
# SYSTEM TWEAK HANDLERS
# ==============================================================================

$btnRunTweaks.Add_Click({
    Execute-STARAction -Name "Registry Optimization" `
        -Situation {
            $btnRunTweaks.Enabled = $false
            $btnRunTweaks.Text = "OPTIMIZING..."
        } `
        -Task { return @{ Continue = $true } } `
        -Action {
            if ($chkCortana.Checked) {
                Write-Log "Disabling Cortana and Web Search..."
                $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
                if (-not (Test-Path $path)) { New-Item $path -Force | Out-Null }
                Set-ItemProperty $path -Name "AllowCortana" -Value 0 -ErrorAction SilentlyContinue
                Set-ItemProperty $path -Name "ConnectedSearchUseWeb" -Value 0 -ErrorAction SilentlyContinue
            }
            if ($chkHighPerf.Checked) {
                Write-Log "Enabling Ultimate Performance Plan..."
                # Import Scheme if missing
                powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
                powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
            }
            if ($chkGameBar.Checked) {
                Write-Log "Removing Xbox/Game Bar persistence..."
                $gbPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
                if (-not (Test-Path $gbPath)) { New-Item $gbPath -Force | Out-Null }
                Set-ItemProperty $gbPath -Name "AppCaptureEnabled" -Value 0 -ErrorAction SilentlyContinue
            }
            if ($chkLongPaths.Checked) {
                Write-Log "Lifting 260 character limit..."
                Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -ErrorAction SilentlyContinue
            }
        } `
        -Result {
            $btnRunTweaks.Enabled = $true
            $btnRunTweaks.Text = "APPLY SELECTED STAR TWEAKS"
            [System.Windows.Forms.MessageBox]::Show("System tweaks applied successfully.", "Success")
        }
})

# Maintenance Tools
$btnSFC.Add_Click({
    Write-Log "Triggered SFC repair."
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'WinClean Pro - Running System File Checker...'; sfc /scannow"
})

$btnDISM.Add_Click({
    Write-Log "Triggered DISM health restoration."
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'WinClean Pro - Running DISM Repair...'; dism /online /cleanup-image /restorehealth"
})

$btnCleanMgr.Add_Click({
    $btnCleanMgr.Enabled = $false
    Write-Log "Executing rapid disk cleanup."
    try {
        Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue
    } finally {
        $btnCleanMgr.Enabled = $true
        [System.Windows.Forms.MessageBox]::Show("Temp folders and Recycle Bin cleared.", "Cleanup Complete")
    }
})

# ==============================================================================
# DIAGNOSTICS & EXTERNAL TOOLS
# ==============================================================================

$btnDiag.Add_Click({
    $btnDiag.Enabled = $false; $btnDiag.Text = "Scanning..."
    $Form.Refresh(); [System.Windows.Forms.Application]::DoEvents()

    Write-Log "Generating Hardware Audit..."
    Import-Module Storage -ErrorAction SilentlyContinue

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("WIN-CLEAN PRO v5.1 HARDWARE AUDIT")
    [void]$sb.AppendLine("Generated: $(Get-Date)")
    [void]$sb.AppendLine("=" * 40)
    
    # Storage Analysis
    $disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
    [void]$sb.AppendLine("`r`n[DRIVE HEALTH]")
    foreach ($d in $disks) {
        [void]$sb.AppendLine(" - Model: $($d.FriendlyName)")
        [void]$sb.AppendLine("   Health: $($d.HealthStatus) | Status: $($d.OperationalStatus)")
    }

    # Platform Analysis
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    [void]$sb.AppendLine("`r`n[PLATFORM]")
    [void]$sb.AppendLine(" - Machine: $($cs.Model)")
    [void]$sb.AppendLine(" - OS: $($os.Caption)")
    [void]$sb.AppendLine(" - RAM: $([math]::Round($os.TotalVisibleMemorySize / 1MB, 2)) GB")

    $txtDiag.Text = $sb.ToString()
    $btnDiag.Enabled = $true; $btnDiag.Text = "GENERATE HARDWARE HEALTH REPORT"
})

$btnWinutil.Add_Click({
    Write-Log "Launching Titus WinUtil."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://christitus.com/win | iex`""
})

# ==============================================================================
# PROFILE SYSTEM
# ==============================================================================

$btnSave.Add_Click({
    $path = Join-Path $Script:ScriptDir "WinCleanProfile.json"
    $profile = @{
        Timestamp = Get-Date -Format "o"
        Tweaks = @{
            Cortana = $chkCortana.Checked
            HighPerf = $chkHighPerf.Checked
            GameBar = $chkGameBar.Checked
            LongPaths = $chkLongPaths.Checked
        }
        Cleanup = @($Global:SelectedApps)
    }
    $profile | ConvertTo-Json -Depth 5 | Out-File $path -Encoding UTF8
    Write-Log "Profile saved to disk."
    $lblProfileStatus.Text = "Saved: $(Get-Date -Format HH:mm)"; $lblProfileStatus.ForeColor = [System.Drawing.Color]::Lime
})

$btnLoad.Add_Click({
    $path = Join-Path $Script:ScriptDir "WinCleanProfile.json"
    if (Test-Path $path) {
        $data = Get-Content $path | ConvertFrom-Json
        $chkCortana.Checked = $data.Tweaks.Cortana
        $chkHighPerf.Checked = $data.Tweaks.HighPerf
        $chkGameBar.Checked = $data.Tweaks.GameBar
        $chkLongPaths.Checked = $data.Tweaks.LongPaths
        
        $Global:SelectedApps.Clear()
        foreach($a in $data.Cleanup) { [void]$Global:SelectedApps.Add($a) }
        Apply-AppFilter
        
        Write-Log "Profile configuration restored."
        $lblProfileStatus.Text = "Profile Loaded"; $lblProfileStatus.ForeColor = [System.Drawing.Color]::Cyan
    }
})

# ==============================================================================
# LAUNCH SEQUENCE
# ==============================================================================
try {
    Write-Host "Activating Graphics Engine..." -ForegroundColor Yellow
    Reload-AppList
    [void]$Form.ShowDialog()
    Write-Log "WinClean Pro Session Terminated." "EXIT"
} catch {
    $errorMsg = "$($_.Exception.GetType().Name): $($_.Exception.Message)"
    Write-Log "FATAL BOOT ERROR: $errorMsg" "ERROR"
    [System.Windows.Forms.MessageBox]::Show(
        "A fatal error occurred during initialization.`n`nCheck the audit log for details.`n`nError: $errorMsg",
        "Critical Failure",
        "OK",
        "Error"
    )
    Start-Sleep -Seconds 5
}
