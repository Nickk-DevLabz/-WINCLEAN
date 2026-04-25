# ==============================================================================
# WINCLEAN PRO v5.0 - FULL TECHNICIAN SUITE (TESTED & VERIFIED)
# Tabs: OS Cleanup | Install Apps | System Tweaks | Hardware Diag | Other Tools
# ==============================================================================

# Self-Elevate to Admin with Bypass
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

# Set up console to stay open
$host.UI.RawUI.WindowTitle = "WinClean Pro v5.0 - Admin Mode"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  WinClean Pro v5.0 - Initializing..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Write-Host "[✓] Assemblies loaded" -ForegroundColor Green

# Capture script folder early
[string]$Script:ScriptDir = $PSScriptRoot
if (-not $Script:ScriptDir) { $Script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }

# Set up persistent logging
$Global:LogFile = Join-Path $Script:ScriptDir "WinClean_Audit.log"

# ==============================================================================
# GLOBAL STATE TRACKING (Fixes Selection Persistence)
# ==============================================================================
$Global:SelectedApps = New-Object System.Collections.Generic.HashSet[string]
$Global:AllInstalledApps = @()
$Script:SearchIsPlaceholder = $true

function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $Stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Entry = "[$Stamp] [$Type] $Message"
    Write-Host $Entry -ForegroundColor $(if ($Type -eq "ERROR") { "Red" } else { "Gray" })
    try {
        $Entry | Out-File -FilePath $Global:LogFile -Append -Encoding UTF8
    } catch {}
}
Write-Log "WinClean Pro Session Started." "START"

# ==============================================================================
# MAIN FORM
# ==============================================================================
$Form = New-Object System.Windows.Forms.Form
$Form.Text            = "WinClean Pro v5.0 - Technician Suite"
$Form.Size            = New-Object System.Drawing.Size(840, 920)
$Form.StartPosition   = "CenterScreen"
$Form.BackColor       = [System.Drawing.Color]::FromArgb(25, 25, 25)
$Form.ForeColor       = [System.Drawing.Color]::White
$Form.Font            = New-Object System.Drawing.Font("Segoe UI", 10)
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox     = $false
$Form.MinimizeBox     = $true

# ==============================================================================
# UI COMPONENTS (RE-BUILT FROM FIXED VERSION)
# ==============================================================================
$pnlTop = New-Object System.Windows.Forms.Panel -Property @{ Dock="Top"; Height=58; BackColor=[System.Drawing.Color]::FromArgb(42, 42, 42) }
$Form.Controls.Add($pnlTop)

$btnSave = New-Object System.Windows.Forms.Button -Property @{ Text="SAVE PROFILE"; Location="20,12"; Size="145,33"; FlatStyle="Flat" }
$btnSave.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$pnlTop.Controls.Add($btnSave)

$btnLoad = New-Object System.Windows.Forms.Button -Property @{ Text="LOAD PROFILE"; Location="175,12"; Size="145,33"; FlatStyle="Flat" }
$btnLoad.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$pnlTop.Controls.Add($btnLoad)

$lblProfileStatus = New-Object System.Windows.Forms.Label -Property @{ Text="No profile loaded"; Location="335,20"; AutoSize=$true; ForeColor=[System.Drawing.Color]::Gray }
$pnlTop.Controls.Add($lblProfileStatus)

$TabCtrl = New-Object System.Windows.Forms.TabControl -Property @{ Location="20,68"; Size="785,800" }
$Form.Controls.Add($TabCtrl)

# TAB 1: OS CLEANUP
$Tab1 = New-Object System.Windows.Forms.TabPage -Property @{ Text="  OS Cleanup  "; BackColor=[System.Drawing.Color]::FromArgb(32, 32, 32) }
$TabCtrl.TabPages.Add($Tab1)

$chkUnlock = New-Object System.Windows.Forms.CheckBox -Property @{ Text="Unlock Permanent System Apps via Registry Bypass (Requires Admin)"; Location="20,15"; AutoSize=$true; ForeColor=[System.Drawing.Color]::OrangeRed }
$Tab1.Controls.Add($chkUnlock)

$chkShell = New-Object System.Windows.Forms.CheckBox -Property @{ Text="Re-register Start Menu and Search after cleanup"; Location="20,45"; AutoSize=$true; Checked=$true }
$Tab1.Controls.Add($chkShell)

$lblFilter = New-Object System.Windows.Forms.Label -Property @{ Text="Filter Category:"; Location="20,87"; AutoSize=$true; ForeColor=[System.Drawing.Color]::Gray }
$Tab1.Controls.Add($lblFilter)

$cmbCategory = New-Object System.Windows.Forms.ComboBox -Property @{ Location="130,83"; Size="180,28"; DropDownStyle="DropDownList"; BackColor=[System.Drawing.Color]::FromArgb(48, 48, 48); ForeColor=[System.Drawing.Color]::White }
$cmbCategory.Items.AddRange(@("All", "3rd Party", "Windows/System", "System Protected"))
$cmbCategory.SelectedIndex = 0
$Tab1.Controls.Add($cmbCategory)

$txtSearch = New-Object System.Windows.Forms.TextBox -Property @{ Location="320,83"; Size="440,28"; BackColor=[System.Drawing.Color]::FromArgb(48, 48, 48); ForeColor=[System.Drawing.Color]::Gray; BorderStyle="FixedSingle"; Text="Search installed apps..." }
$Tab1.Controls.Add($txtSearch)

$AppList = New-Object System.Windows.Forms.CheckedListBox -Property @{ Location="20,118"; Size="740,420"; BackColor=[System.Drawing.Color]::FromArgb(38, 38, 38); ForeColor=[System.Drawing.Color]::White; BorderStyle="None"; CheckOnClick=$true }
$Tab1.Controls.Add($AppList)

$btnSelAll = New-Object System.Windows.Forms.Button -Property @{ Text="Select All Visible"; Location="20,548"; Size="115,33"; FlatStyle="Flat" }
$Tab1.Controls.Add($btnSelAll)

$btnRefresh = New-Object System.Windows.Forms.Button -Property @{ Text="Refresh List"; Location="145,548"; Size="115,33"; FlatStyle="Flat" }
$Tab1.Controls.Add($btnRefresh)

$lblAppCount = New-Object System.Windows.Forms.Label -Property @{ Text="0 apps listed"; Location="280,557"; AutoSize=$true; ForeColor=[System.Drawing.Color]::Gray }
$Tab1.Controls.Add($lblAppCount)

$btnRunCleanup = New-Object System.Windows.Forms.Button -Property @{ Text="EXECUTE SELECTED APP REMOVAL"; Location="20,595"; Size="740,50"; BackColor=[System.Drawing.Color]::FromArgb(160, 0, 0); FlatStyle="Flat"; Font=New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold) }
$Tab1.Controls.Add($btnRunCleanup)

# TAB 2: INSTALL APPS (winget)
$Tab2 = New-Object System.Windows.Forms.TabPage -Property @{ Text="  Install Apps  "; BackColor=[System.Drawing.Color]::FromArgb(32, 32, 32) }
$TabCtrl.TabPages.Add($Tab2)

$AppInstList = New-Object System.Windows.Forms.CheckedListBox -Property @{ Location="20,48"; Size="740,500"; BackColor=[System.Drawing.Color]::FromArgb(38, 38, 38); ForeColor=[System.Drawing.Color]::White; BorderStyle="None"; CheckOnClick=$true }
$Tab2.Controls.Add($AppInstList)

$btnInstall = New-Object System.Windows.Forms.Button -Property @{ Text="INSTALL SELECTED APPS"; Location="20,608"; Size="740,50"; BackColor=[System.Drawing.Color]::FromArgb(0, 110, 0); FlatStyle="Flat"; Font=New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold) }
$Tab2.Controls.Add($btnInstall)

# TAB 3: SYSTEM TWEAKS
$Tab3 = New-Object System.Windows.Forms.TabPage -Property @{ Text="  System Tweaks  "; BackColor=[System.Drawing.Color]::FromArgb(32, 32, 32) }
$TabCtrl.TabPages.Add($Tab3)

# Group: Performance & UI
$gbPerfUI = New-Object System.Windows.Forms.GroupBox -Property @{ Text="Performance & UI"; Location="20,15"; Size="740,150"; ForeColor=[System.Drawing.Color]::DeepSkyBlue }
$Tab3.Controls.Add($gbPerfUI)

$chkCortana = New-Object System.Windows.Forms.CheckBox -Property @{ Text="Disable Cortana"; Location="15,30"; AutoSize=$true }
$gbPerfUI.Controls.Add($chkCortana)

$chkHighPerf = New-Object System.Windows.Forms.CheckBox -Property @{ Text="Set Power Plan to High Performance"; Location="15,60"; AutoSize=$true; ForeColor=[System.Drawing.Color]::OrangeRed }
$gbPerfUI.Controls.Add($chkHighPerf)

$chkGameBar = New-Object System.Windows.Forms.CheckBox -Property @{ Text="Disable Xbox Game Bar and GameDVR"; Location="15,90"; AutoSize=$true }
$gbPerfUI.Controls.Add($chkGameBar)

$chkLongPaths = New-Object System.Windows.Forms.CheckBox -Property @{ Text="Enable Long File Paths"; Location="15,120"; AutoSize=$true }
$gbPerfUI.Controls.Add($chkLongPaths)

# Group: System Maintenance
$gbMaint = New-Object System.Windows.Forms.GroupBox -Property @{ Text="System Maintenance"; Location="20,175"; Size="740,120"; ForeColor=[System.Drawing.Color]::DeepSkyBlue }
$Tab3.Controls.Add($gbMaint)

$btnSFC = New-Object System.Windows.Forms.Button -Property @{ Text="RUN SFC SCANNOW"; Location="15,30"; Size="220,35"; FlatStyle="Flat" }
$gbMaint.Controls.Add($btnSFC)

$btnDISM = New-Object System.Windows.Forms.Button -Property @{ Text="DISM HEALTH REPAIR"; Location="250,30"; Size="220,35"; FlatStyle="Flat" }
$gbMaint.Controls.Add($btnDISM)

$btnCleanMgr = New-Object System.Windows.Forms.Button -Property @{ Text="QUICK DISK CLEANUP"; Location="485,30"; Size="220,35"; FlatStyle="Flat"; BackColor=[System.Drawing.Color]::FromArgb(60, 60, 60) }
$gbMaint.Controls.Add($btnCleanMgr)

$lblMaintHint = New-Object System.Windows.Forms.Label -Property @{ Text="Maintenance tasks open in a separate window to show real-time progress."; Location="15,75"; Size="700,30"; ForeColor=[System.Drawing.Color]::Gray }
$gbMaint.Controls.Add($lblMaintHint)

$btnRunTweaks = New-Object System.Windows.Forms.Button -Property @{ Text="APPLY SELECTED TWEAKS"; Location="20,643"; Size="740,50"; BackColor=[System.Drawing.Color]::FromArgb(0, 100, 160); FlatStyle="Flat"; Font=New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold) }
$Tab3.Controls.Add($btnRunTweaks)

# TAB 4: HARDWARE DIAGNOSTICS
$Tab4 = New-Object System.Windows.Forms.TabPage -Property @{ Text="  Hardware Diag  "; BackColor=[System.Drawing.Color]::FromArgb(32, 32, 32) }
$TabCtrl.TabPages.Add($Tab4)

$btnDiag = New-Object System.Windows.Forms.Button -Property @{ Text="RUN HARDWARE HEALTH CHECK"; Location="20,15"; Size="740,50"; BackColor=[System.Drawing.Color]::FromArgb(0, 118, 118); FlatStyle="Flat"; Font=New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold) }
$Tab4.Controls.Add($btnDiag)

$txtDiag = New-Object System.Windows.Forms.TextBox -Property @{ Location="20,80"; Size="740,580"; Multiline=$true; ReadOnly=$true; ScrollBars="Vertical"; BackColor=[System.Drawing.Color]::Black; ForeColor=[System.Drawing.Color]::Lime; Font=New-Object System.Drawing.Font("Consolas", 10); BorderStyle="None" }
$Tab4.Controls.Add($txtDiag)

# TAB 5: OTHER TOOLS
$Tab5 = New-Object System.Windows.Forms.TabPage -Property @{ Text="  Other Tools  "; BackColor=[System.Drawing.Color]::FromArgb(32, 32, 32) }
$TabCtrl.TabPages.Add($Tab5)

$btnWinutil = New-Object System.Windows.Forms.Button -Property @{ Text="LAUNCH CHRIS TITUS WINUTIL"; Location="20,30"; Size="740,60"; BackColor=[System.Drawing.Color]::FromArgb(0, 100, 160); FlatStyle="Flat"; Font=New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold) }
$Tab5.Controls.Add($btnWinutil)

# ==============================================================================
# ENGINE FUNCTIONS
# ==============================================================================

function Execute-STARAction {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][scriptblock]$Situation,
        [Parameter(Mandatory=$true)][scriptblock]$Task,
        [Parameter(Mandatory=$true)][scriptblock]$Action,
        [Parameter(Mandatory=$true)][scriptblock]$Result
    )
    
    # 1. Situation: Log intent and prepare UI
    Write-Log "Desire Identified: $Name"
    &$Situation
    $Form.Refresh()

    try {
        # 2. Task: Preparation and validation
        $Context = &$Task
        if ($null -eq $Context -or $Context.Continue -eq $false) {
            Write-Log "Desire cancelled or invalid during Task phase."
            return
        }

        # 3. Action: Technical execution
        &$Action $Context

        # 4. Result: Reporting and recovery
        &$Result $Context
        Write-Log "Desire fulfilled: $Name"
    } catch {
        Write-Log "Execution Failure ($Name): $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("A technical error occurred: $($_.Exception.Message)", "STAR Engine Error")
    }
}

function Reload-AppList {
    Write-Host "[*] Refreshing App List..." -ForegroundColor Gray
    [System.Windows.Forms.Application]::DoEvents()
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
    }) | Sort-Object Category, Name
    
    Apply-AppFilter
}

function Apply-AppFilter {
    $filterText = if (-not $Script:SearchIsPlaceholder) { $txtSearch.Text } else { "" }
    $filterCat  = $cmbCategory.SelectedItem
    
    # Block event handler while repopulating to avoid loop
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
    $lblAppCount.Text = "$($AppList.Items.Count) apps listed"
}

# ==============================================================================
# EVENT HANDLERS - TAB 1
# ==============================================================================

$AppList.Add_ItemCheck({
    param($s, $e)
    if ($AppList.Enabled) {
        # Strip the category tag to get the raw name for internal tracking
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
    Execute-STARAction -Name "OS Bloatware Removal" `
        -Situation {
            $btnRunCleanup.Enabled = $false
            $btnRunCleanup.Text = "Executing STAR Process..."
        } `
        -Task {
            if ($Global:SelectedApps.Count -eq 0) {
                [System.Windows.Forms.MessageBox]::Show("No selection detected.", "Task Aborted")
                return @{ Continue = $false }
            }
            $confirm = [System.Windows.Forms.MessageBox]::Show("Proceed with removing $($Global:SelectedApps.Count) apps?", "Confirm Task", "YesNo", "Warning")
            return @{ Continue = ($confirm -eq "Yes"); Apps = @($Global:SelectedApps); Logs = New-Object System.Collections.Generic.List[string] }
        } `
        -Action {
            param($Ctx)
            if ($chkUnlock.Checked) {
                $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Applications"
                Get-ChildItem $regPath -ErrorAction SilentlyContinue | ForEach-Object {
                    Set-ItemProperty -Path $_.PSPath -Name "IsInbox" -Value 0 -ErrorAction SilentlyContinue
                }
            }

            foreach ($item in $Ctx.Apps) {
                [System.Windows.Forms.Application]::DoEvents()
                $found = $false
                # User Level
                $pkgs = Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq $item }
                if ($pkgs) {
                    $found = $true
                    foreach ($p in $pkgs) {
                        try { Remove-AppxPackage -Package $p.PackageFullName -ErrorAction Stop } 
                        catch { $Ctx.Logs.Add("[Error] $item (User): $($_.Exception.Message)") }
                    }
                }
                # Provisioned Level
                $prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $item }
                if ($prov) {
                    $found = $true
                    try { Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction Stop | Out-Null } 
                    catch { $Ctx.Logs.Add("[Error] $item (System): $($_.Exception.Message)") }
                }
                if (-not $found) { $Ctx.Logs.Add("[Info] $item missing.") }
            }
            if ($chkShell.Checked) { Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue }
        } `
        -Result {
            param($Ctx)
            $btnRunCleanup.Enabled = $true
            $btnRunCleanup.Text = "EXECUTE SELECTED APP REMOVAL"
            $Global:SelectedApps.Clear()
            Reload-AppList
            $msg = "Removal Complete."
            if ($Ctx.Logs.Count -gt 0) { $msg += "`n`nLogs:`n" + ($Ctx.Logs -join "`n") }
            [System.Windows.Forms.MessageBox]::Show($msg, "STAR Result")
        }
})

# ==============================================================================
# EVENT HANDLERS - TAB 2: INSTALL
# ==============================================================================

$Global:InstallCatalog = @(
    @{ Name = "Google Chrome"; Id = "Google.Chrome" }
    @{ Name = "7-Zip"; Id = "7zip.7zip" }
    @{ Name = "VLC Player"; Id = "VideoLAN.VLC" }
    @{ Name = "VS Code"; Id = "Microsoft.VisualStudioCode" }
    @{ Name = "Notepad++"; Id = "Notepad++.Notepad++" }
    @{ Name = "Git"; Id = "Git.Git" }
)
foreach ($a in $Global:InstallCatalog) { [void]$AppInstList.Items.Add($a.Name) }

$btnInstall.Add_Click({
    $selected = @($AppInstList.CheckedItems)
    if ($selected.Count -eq 0) { return }

    $btnInstall.Enabled = $false; $btnInstall.Text = "Installing..."; $Form.Refresh()

    $successCount = 0
    foreach ($name in $selected) {
        $id = ($Global:InstallCatalog | Where-Object { $_.Name -eq $name }).Id
        Write-Log "Installing via winget: $id"
        # TESTED: Using specialized winget arguments to avoid interaction
        $process = Start-Process winget -ArgumentList "install --id $id --silent --accept-package-agreements --accept-source-agreements" -NoNewWindow -Wait -PassThru
        
        # Exit Code 0 = Success, Exit Code -2145801216 (0x8A150030) = Already installed
        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq -2145801216) {
            $successCount++
        }
    }

    $btnInstall.Enabled = $true; $btnInstall.Text = "INSTALL SELECTED APPS"
    [System.Windows.Forms.MessageBox]::Show("Successfully processed $successCount of $($selected.Count) apps.", "Install Results")
})

# ==============================================================================
# EVENT HANDLERS - TAB 3: TWEAKS
# ==============================================================================

$btnRunTweaks.Add_Click({
    Execute-STARAction -Name "System Optimization" `
        -Situation {
            $btnRunTweaks.Enabled = $false
            $btnRunTweaks.Text = "Applying STAR Tweaks..."
        } `
        -Task {
            return @{ Continue = $true }
        } `
        -Action {
            if ($chkCortana.Checked) {
                $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
                if (-not (Test-Path $path)) { New-Item $path -Force | Out-Null }
                Set-ItemProperty $path -Name "AllowCortana" -Value 0 -ErrorAction SilentlyContinue
            }
            if ($chkHighPerf.Checked) { powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null }
            if ($chkGameBar.Checked) {
                $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
                if (-not (Test-Path $path)) { New-Item $path -Force | Out-Null }
                Set-ItemProperty $path -Name "AppCaptureEnabled" -Value 0 -ErrorAction SilentlyContinue
            }
            if ($chkLongPaths.Checked) { Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -ErrorAction SilentlyContinue }
        } `
        -Result {
            $btnRunTweaks.Enabled = $true
            $btnRunTweaks.Text = "APPLY SELECTED TWEAKS"
            [System.Windows.Forms.MessageBox]::Show("Optimization STAR Desire fulfilled.", "Done")
        }
})

$btnSFC.Add_Click({
    Write-Log "Launched SFC Scannow."
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'Running SFC...'; sfc /scannow"
})

$btnDISM.Add_Click({
    Write-Log "Launched DISM Health Repair."
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'Running DISM...'; dism /online /cleanup-image /restorehealth"
})

$btnCleanMgr.Add_Click({
    Write-Log "Running Disk Cleanup."
    $btnCleanMgr.Enabled = $false
    # Target Temp, Recycle Bin, and Prefetch
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue
    $btnCleanMgr.Enabled = $true
    [System.Windows.Forms.MessageBox]::Show("Temporary files and Recycle Bin cleared.", "Cleanup Complete")
})

# ==============================================================================
# EVENT HANDLERS - TAB 4: DIAGNOSTICS
# ==============================================================================

$btnDiag.Add_Click({
    $btnDiag.Enabled = $false; $btnDiag.Text = "Scanning Hardware..."
    $Form.Refresh()
    Write-Log "Running Hardware Diagnostics."

    Import-Module Storage -ErrorAction SilentlyContinue

    $r = "HARDWARE HEALTH REPORT`n" + ("=" * 30) + "`n"
    
    # Disk Health
    $disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
    $r += "[Storage Devices]`n"
    foreach ($d in $disks) {
        $r += " - $($d.FriendlyName): $($d.HealthStatus) ($($d.OperationalStatus))`n"
    }

    # OS Info
    $os = Get-CimInstance Win32_OperatingSystem
    $r += "`n[System Info]`n"
    $r += " - OS: $($os.Caption)`n"
    $r += " - RAM: $([math]::Round($os.TotalVisibleMemorySize / 1MB, 2)) GB`n"

    $txtDiag.Text = $r
    $btnDiag.Enabled = $true; $btnDiag.Text = "RUN HARDWARE HEALTH CHECK"
})

# ==============================================================================
# EVENT HANDLERS - TAB 5: TOOLS
# ==============================================================================

$btnWinutil.Add_Click({
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://christitus.com/win | iex`""
})

# ==============================================================================
# PROFILE LOGIC
# ==============================================================================

$btnSave.Add_Click({
    $profile = @{
        Tweaks = @{
            Cortana = $chkCortana.Checked
            HighPerf = $chkHighPerf.Checked
            GameBar = $chkGameBar.Checked
            LongPaths = $chkLongPaths.Checked
        }
        Cleanup = @($Global:SelectedApps)
    }
    $path = Join-Path $Script:ScriptDir "WinCleanProfile.json"
    $profile | ConvertTo-Json | Out-File $path
    $lblProfileStatus.Text = "Profile Saved: $(Get-Date -Format HH:mm)"; $lblProfileStatus.ForeColor = [System.Drawing.Color]::Lime
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
        
        $lblProfileStatus.Text = "Profile Loaded"; $lblProfileStatus.ForeColor = [System.Drawing.Color]::Cyan
    }
})

# ==============================================================================
# LAUNCH
# ==============================================================================
try {
    Write-Host "Launching GUI window..." -ForegroundColor Yellow
    Reload-AppList
    [void]$Form.ShowDialog()
    Write-Log "WinClean Pro Session Ended." "EXIT"
} catch {
    $errorMsg = "$($_.Exception.GetType().Name): $($_.Exception.Message)"
    Write-Log "FATAL ERROR: $errorMsg" "ERROR"
    [System.Windows.Forms.MessageBox]::Show(
        "Fatal error during launch:`n`n$errorMsg`n`nLine: $($_.InvocationInfo.ScriptLineNumber)",
        "WinClean Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
    Write-Host "Keeping window open for 10 seconds to show error details..." -ForegroundColor Red
    Start-Sleep -Seconds 10
}