# ==============================================================================
# WINCLEAN PRO v4.0 - FULL TECHNICIAN SUITE (Clean Rewrite)
# Tabs: OS Cleanup | Install Apps | System Tweaks | Hardware Diag
# ==============================================================================

# Self-Elevate to Admin with Bypass
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Capture script folder early (empty inside event scriptblocks)
[string]$Script:ScriptDir = $PSScriptRoot
if (-not $Script:ScriptDir) { $Script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }

# ==============================================================================
# MAIN FORM
# ==============================================================================
$Form = New-Object System.Windows.Forms.Form
$Form.Text            = "WinClean Pro v4.0 - Technician Suite"
$Form.Size            = New-Object System.Drawing.Size(840, 920)
$Form.StartPosition   = "CenterScreen"
$Form.BackColor       = [System.Drawing.Color]::FromArgb(25, 25, 25)
$Form.ForeColor       = [System.Drawing.Color]::White
$Form.Font            = New-Object System.Drawing.Font("Segoe UI", 10)
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox     = $false

# ==============================================================================
# TOP PROFILE BAR
# ==============================================================================
$pnlTop           = New-Object System.Windows.Forms.Panel
$pnlTop.Dock      = "Top"
$pnlTop.Height    = 58
$pnlTop.BackColor = [System.Drawing.Color]::FromArgb(42, 42, 42)
$Form.Controls.Add($pnlTop)

$btnSave          = New-Object System.Windows.Forms.Button
$btnSave.Text     = "SAVE PROFILE"
$btnSave.Location = New-Object System.Drawing.Point(20, 12)
$btnSave.Size     = New-Object System.Drawing.Size(145, 33)
$btnSave.FlatStyle = "Flat"
$btnSave.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$pnlTop.Controls.Add($btnSave)

$btnLoad          = New-Object System.Windows.Forms.Button
$btnLoad.Text     = "LOAD PROFILE"
$btnLoad.Location = New-Object System.Drawing.Point(175, 12)
$btnLoad.Size     = New-Object System.Drawing.Size(145, 33)
$btnLoad.FlatStyle = "Flat"
$btnLoad.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$pnlTop.Controls.Add($btnLoad)

$lblProfileStatus           = New-Object System.Windows.Forms.Label
$lblProfileStatus.Text      = "No profile loaded"
$lblProfileStatus.Location  = New-Object System.Drawing.Point(335, 20)
$lblProfileStatus.AutoSize  = $true
$lblProfileStatus.ForeColor = [System.Drawing.Color]::Gray
$pnlTop.Controls.Add($lblProfileStatus)

# ==============================================================================
# TAB CONTROL
# ==============================================================================
$TabCtrl          = New-Object System.Windows.Forms.TabControl
$TabCtrl.Location = New-Object System.Drawing.Point(20, 68)
$TabCtrl.Size     = New-Object System.Drawing.Size(785, 800)
$Form.Controls.Add($TabCtrl)

# ==============================================================================
# TAB 1: OS CLEANUP
# ==============================================================================
$Tab1            = New-Object System.Windows.Forms.TabPage
$Tab1.Text       = "  OS Cleanup  "
$Tab1.BackColor  = [System.Drawing.Color]::FromArgb(32, 32, 32)
$TabCtrl.TabPages.Add($Tab1)

$chkUnlock          = New-Object System.Windows.Forms.CheckBox
$chkUnlock.Text     = "Unlock Permanent System Apps via Registry Bypass  (use with caution)"
$chkUnlock.Location = New-Object System.Drawing.Point(20, 15)
$chkUnlock.AutoSize = $true
$chkUnlock.ForeColor = [System.Drawing.Color]::OrangeRed
$Tab1.Controls.Add($chkUnlock)

$chkShell          = New-Object System.Windows.Forms.CheckBox
$chkShell.Text     = "Re-register Start Menu and Search after cleanup  (recommended)"
$chkShell.Location = New-Object System.Drawing.Point(20, 45)
$chkShell.AutoSize = $true
$chkShell.Checked  = $true
$Tab1.Controls.Add($chkShell)

$txtSearch            = New-Object System.Windows.Forms.TextBox
$txtSearch.Location   = New-Object System.Drawing.Point(20, 83)
$txtSearch.Size       = New-Object System.Drawing.Size(740, 28)
$txtSearch.BackColor  = [System.Drawing.Color]::FromArgb(48, 48, 48)
$txtSearch.ForeColor  = [System.Drawing.Color]::Gray
$txtSearch.BorderStyle = "FixedSingle"
$txtSearch.Text       = "Search installed apps..."
$Tab1.Controls.Add($txtSearch)

$AppList              = New-Object System.Windows.Forms.CheckedListBox
$AppList.Location     = New-Object System.Drawing.Point(20, 118)
$AppList.Size         = New-Object System.Drawing.Size(740, 420)
$AppList.BackColor    = [System.Drawing.Color]::FromArgb(38, 38, 38)
$AppList.ForeColor    = [System.Drawing.Color]::White
$AppList.BorderStyle  = "None"
$AppList.CheckOnClick = $true
$Tab1.Controls.Add($AppList)

$btnSelAll          = New-Object System.Windows.Forms.Button
$btnSelAll.Text     = "Select All"
$btnSelAll.Location = New-Object System.Drawing.Point(20, 548)
$btnSelAll.Size     = New-Object System.Drawing.Size(115, 33)
$btnSelAll.FlatStyle = "Flat"
$Tab1.Controls.Add($btnSelAll)

$btnDeselAll          = New-Object System.Windows.Forms.Button
$btnDeselAll.Text     = "Deselect All"
$btnDeselAll.Location = New-Object System.Drawing.Point(145, 548)
$btnDeselAll.Size     = New-Object System.Drawing.Size(115, 33)
$btnDeselAll.FlatStyle = "Flat"
$Tab1.Controls.Add($btnDeselAll)

$btnRefresh          = New-Object System.Windows.Forms.Button
$btnRefresh.Text     = "Refresh List"
$btnRefresh.Location = New-Object System.Drawing.Point(270, 548)
$btnRefresh.Size     = New-Object System.Drawing.Size(115, 33)
$btnRefresh.FlatStyle = "Flat"
$Tab1.Controls.Add($btnRefresh)

$lblAppCount           = New-Object System.Windows.Forms.Label
$lblAppCount.Text      = "Click Refresh List to load apps"
$lblAppCount.Location  = New-Object System.Drawing.Point(400, 557)
$lblAppCount.AutoSize  = $true
$lblAppCount.ForeColor = [System.Drawing.Color]::Gray
$Tab1.Controls.Add($lblAppCount)

$btnRunCleanup           = New-Object System.Windows.Forms.Button
$btnRunCleanup.Text      = "EXECUTE SELECTED APP REMOVAL"
$btnRunCleanup.Location  = New-Object System.Drawing.Point(20, 595)
$btnRunCleanup.Size      = New-Object System.Drawing.Size(740, 50)
$btnRunCleanup.BackColor = [System.Drawing.Color]::FromArgb(160, 0, 0)
$btnRunCleanup.FlatStyle = "Flat"
$btnRunCleanup.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$Tab1.Controls.Add($btnRunCleanup)

# ==============================================================================
# TAB 2: INSTALL APPS (winget)
# ==============================================================================
$Tab2            = New-Object System.Windows.Forms.TabPage
$Tab2.Text       = "  Install Apps  "
$Tab2.BackColor  = [System.Drawing.Color]::FromArgb(32, 32, 32)
$TabCtrl.TabPages.Add($Tab2)

$lblInstHdr           = New-Object System.Windows.Forms.Label
$lblInstHdr.Text      = "Select apps to download and install via winget (Windows Package Manager):"
$lblInstHdr.Location  = New-Object System.Drawing.Point(20, 15)
$lblInstHdr.AutoSize  = $true
$lblInstHdr.ForeColor = [System.Drawing.Color]::LightGray
$Tab2.Controls.Add($lblInstHdr)

$AppInstList              = New-Object System.Windows.Forms.CheckedListBox
$AppInstList.Location     = New-Object System.Drawing.Point(20, 48)
$AppInstList.Size         = New-Object System.Drawing.Size(740, 500)
$AppInstList.BackColor    = [System.Drawing.Color]::FromArgb(38, 38, 38)
$AppInstList.ForeColor    = [System.Drawing.Color]::White
$AppInstList.BorderStyle  = "None"
$AppInstList.CheckOnClick = $true
$Tab2.Controls.Add($AppInstList)

$btnInstSelAll          = New-Object System.Windows.Forms.Button
$btnInstSelAll.Text     = "Select All"
$btnInstSelAll.Location = New-Object System.Drawing.Point(20, 560)
$btnInstSelAll.Size     = New-Object System.Drawing.Size(115, 33)
$btnInstSelAll.FlatStyle = "Flat"
$Tab2.Controls.Add($btnInstSelAll)

$btnInstDeselAll          = New-Object System.Windows.Forms.Button
$btnInstDeselAll.Text     = "Deselect All"
$btnInstDeselAll.Location = New-Object System.Drawing.Point(145, 560)
$btnInstDeselAll.Size     = New-Object System.Drawing.Size(115, 33)
$btnInstDeselAll.FlatStyle = "Flat"
$Tab2.Controls.Add($btnInstDeselAll)

$btnInstall           = New-Object System.Windows.Forms.Button
$btnInstall.Text      = "INSTALL SELECTED APPS"
$btnInstall.Location  = New-Object System.Drawing.Point(20, 608)
$btnInstall.Size      = New-Object System.Drawing.Size(740, 50)
$btnInstall.BackColor = [System.Drawing.Color]::FromArgb(0, 110, 0)
$btnInstall.FlatStyle = "Flat"
$btnInstall.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$Tab2.Controls.Add($btnInstall)

# ==============================================================================
# TAB 3: SYSTEM TWEAKS
# ==============================================================================
$Tab3            = New-Object System.Windows.Forms.TabPage
$Tab3.Text       = "  System Tweaks  "
$Tab3.BackColor  = [System.Drawing.Color]::FromArgb(32, 32, 32)
$TabCtrl.TabPages.Add($Tab3)

# Group: System Restore
$gbRestore           = New-Object System.Windows.Forms.GroupBox
$gbRestore.Text      = "System Safety"
$gbRestore.Location  = New-Object System.Drawing.Point(20, 15)
$gbRestore.Size      = New-Object System.Drawing.Size(740, 68)
$gbRestore.ForeColor = [System.Drawing.Color]::DeepSkyBlue
$Tab3.Controls.Add($gbRestore)

$chkRestore          = New-Object System.Windows.Forms.CheckBox
$chkRestore.Text     = "Create a System Restore Point before making any changes  (recommended)"
$chkRestore.Location = New-Object System.Drawing.Point(15, 28)
$chkRestore.AutoSize = $true
$chkRestore.Checked  = $true
$gbRestore.Controls.Add($chkRestore)

# Group: Windows Update
$gbUpdate           = New-Object System.Windows.Forms.GroupBox
$gbUpdate.Text      = "Windows Update"
$gbUpdate.Location  = New-Object System.Drawing.Point(20, 95)
$gbUpdate.Size      = New-Object System.Drawing.Size(740, 100)
$gbUpdate.ForeColor = [System.Drawing.Color]::DeepSkyBlue
$Tab3.Controls.Add($gbUpdate)

$radioUpdateDefault         = New-Object System.Windows.Forms.RadioButton
$radioUpdateDefault.Text    = "Keep Default"
$radioUpdateDefault.Location = New-Object System.Drawing.Point(15, 28)
$radioUpdateDefault.AutoSize = $true
$radioUpdateDefault.Checked = $true
$gbUpdate.Controls.Add($radioUpdateDefault)

$radioUpdatePause           = New-Object System.Windows.Forms.RadioButton
$radioUpdatePause.Text      = "Pause for 120 Days"
$radioUpdatePause.Location  = New-Object System.Drawing.Point(155, 28)
$radioUpdatePause.AutoSize  = $true
$gbUpdate.Controls.Add($radioUpdatePause)

$radioUpdateDisable           = New-Object System.Windows.Forms.RadioButton
$radioUpdateDisable.Text      = "Disable Completely"
$radioUpdateDisable.Location  = New-Object System.Drawing.Point(320, 28)
$radioUpdateDisable.AutoSize  = $true
$gbUpdate.Controls.Add($radioUpdateDisable)

$chkNoDriverUpdate          = New-Object System.Windows.Forms.CheckBox
$chkNoDriverUpdate.Text     = "Block Windows Update from auto-installing / replacing drivers"
$chkNoDriverUpdate.Location = New-Object System.Drawing.Point(15, 62)
$chkNoDriverUpdate.AutoSize = $true
$chkNoDriverUpdate.Checked  = $true
$gbUpdate.Controls.Add($chkNoDriverUpdate)

# Group: Remove Bloat
$gbRemove           = New-Object System.Windows.Forms.GroupBox
$gbRemove.Text      = "Remove Built-in Bloat"
$gbRemove.Location  = New-Object System.Drawing.Point(20, 208)
$gbRemove.Size      = New-Object System.Drawing.Size(740, 120)
$gbRemove.ForeColor = [System.Drawing.Color]::DeepSkyBlue
$Tab3.Controls.Add($gbRemove)

$chkEdge          = New-Object System.Windows.Forms.CheckBox
$chkEdge.Text     = "Force uninstall Microsoft Edge"
$chkEdge.Location = New-Object System.Drawing.Point(15, 28)
$chkEdge.AutoSize = $true
$gbRemove.Controls.Add($chkEdge)

$chkOneDrive          = New-Object System.Windows.Forms.CheckBox
$chkOneDrive.Text     = "Uninstall OneDrive"
$chkOneDrive.Location = New-Object System.Drawing.Point(15, 58)
$chkOneDrive.AutoSize = $true
$gbRemove.Controls.Add($chkOneDrive)

$chkProvisionedAll          = New-Object System.Windows.Forms.CheckBox
$chkProvisionedAll.Text     = "Remove ALL provisioned (pre-installed) packages from the Windows image"
$chkProvisionedAll.Location = New-Object System.Drawing.Point(15, 88)
$chkProvisionedAll.AutoSize = $true
$gbRemove.Controls.Add($chkProvisionedAll)

# Group: Privacy & Telemetry
$gbTelemetry           = New-Object System.Windows.Forms.GroupBox
$gbTelemetry.Text      = "Privacy & Telemetry"
$gbTelemetry.Location  = New-Object System.Drawing.Point(20, 340)
$gbTelemetry.Size      = New-Object System.Drawing.Size(740, 125)
$gbTelemetry.ForeColor = [System.Drawing.Color]::DeepSkyBlue
$Tab3.Controls.Add($gbTelemetry)

$chkTelemetry          = New-Object System.Windows.Forms.CheckBox
$chkTelemetry.Text     = "Disable DiagTrack and dmwappushservice telemetry services"
$chkTelemetry.Location = New-Object System.Drawing.Point(15, 28)
$chkTelemetry.AutoSize = $true
$chkTelemetry.Checked  = $true
$gbTelemetry.Controls.Add($chkTelemetry)

$chkAdvID          = New-Object System.Windows.Forms.CheckBox
$chkAdvID.Text     = "Disable Advertising ID"
$chkAdvID.Location = New-Object System.Drawing.Point(15, 58)
$chkAdvID.AutoSize = $true
$chkAdvID.Checked  = $true
$gbTelemetry.Controls.Add($chkAdvID)

$chkDeepClean          = New-Object System.Windows.Forms.CheckBox
$chkDeepClean.Text     = "Deep clean WindowsApps and AppRepository folders  (reclaims disk space)"
$chkDeepClean.Location = New-Object System.Drawing.Point(15, 88)
$chkDeepClean.AutoSize = $true
$gbTelemetry.Controls.Add($chkDeepClean)

$btnRunTweaks           = New-Object System.Windows.Forms.Button
$btnRunTweaks.Text      = "APPLY SELECTED TWEAKS"
$btnRunTweaks.Location  = New-Object System.Drawing.Point(20, 480)
$btnRunTweaks.Size      = New-Object System.Drawing.Size(740, 50)
$btnRunTweaks.BackColor = [System.Drawing.Color]::FromArgb(0, 100, 160)
$btnRunTweaks.FlatStyle = "Flat"
$btnRunTweaks.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$Tab3.Controls.Add($btnRunTweaks)

$btnReboot           = New-Object System.Windows.Forms.Button
$btnReboot.Text      = "REBOOT SYSTEM"
$btnReboot.Location  = New-Object System.Drawing.Point(20, 545)
$btnReboot.Size      = New-Object System.Drawing.Size(740, 50)
$btnReboot.BackColor = [System.Drawing.Color]::FromArgb(90, 0, 0)
$btnReboot.FlatStyle = "Flat"
$Tab3.Controls.Add($btnReboot)

# ==============================================================================
# TAB 4: HARDWARE DIAGNOSTICS
# ==============================================================================
$Tab4            = New-Object System.Windows.Forms.TabPage
$Tab4.Text       = "  Hardware Diag  "
$Tab4.BackColor  = [System.Drawing.Color]::FromArgb(32, 32, 32)
$TabCtrl.TabPages.Add($Tab4)

$btnDiag           = New-Object System.Windows.Forms.Button
$btnDiag.Text      = "RUN HARDWARE HEALTH CHECK"
$btnDiag.Location  = New-Object System.Drawing.Point(20, 15)
$btnDiag.Size      = New-Object System.Drawing.Size(740, 50)
$btnDiag.BackColor = [System.Drawing.Color]::FromArgb(0, 118, 118)
$btnDiag.FlatStyle = "Flat"
$btnDiag.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$Tab4.Controls.Add($btnDiag)

$btnSaveDiag           = New-Object System.Windows.Forms.Button
$btnSaveDiag.Text      = "Save Report to Desktop"
$btnSaveDiag.Location  = New-Object System.Drawing.Point(20, 75)
$btnSaveDiag.Size      = New-Object System.Drawing.Size(210, 33)
$btnSaveDiag.FlatStyle = "Flat"
$btnSaveDiag.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$Tab4.Controls.Add($btnSaveDiag)

$txtDiag              = New-Object System.Windows.Forms.TextBox
$txtDiag.Location     = New-Object System.Drawing.Point(20, 118)
$txtDiag.Size         = New-Object System.Drawing.Size(740, 550)
$txtDiag.Multiline    = $true
$txtDiag.ReadOnly     = $true
$txtDiag.ScrollBars   = "Vertical"
$txtDiag.BackColor    = [System.Drawing.Color]::Black
$txtDiag.ForeColor    = [System.Drawing.Color]::Lime
$txtDiag.Font         = New-Object System.Drawing.Font("Consolas", 10)
$txtDiag.BorderStyle  = "None"
$Tab4.Controls.Add($txtDiag)

# ==============================================================================
# DATA INITIALIZATION
# ==============================================================================

# Winget app catalog
$Global:InstallCatalog = @(
    [PSCustomObject]@{ Name = "Google Chrome";    Id = "Google.Chrome" }
    [PSCustomObject]@{ Name = "Mozilla Firefox";  Id = "Mozilla.Firefox" }
    [PSCustomObject]@{ Name = "Brave Browser";    Id = "Brave.Brave" }
    [PSCustomObject]@{ Name = "7-Zip";            Id = "7zip.7zip" }
    [PSCustomObject]@{ Name = "VLC Media Player"; Id = "VideoLAN.VLC" }
    [PSCustomObject]@{ Name = "Notepad++";        Id = "Notepad++.Notepad++" }
    [PSCustomObject]@{ Name = "VS Code";          Id = "Microsoft.VisualStudioCode" }
    [PSCustomObject]@{ Name = "PowerToys";        Id = "Microsoft.PowerToys" }
    [PSCustomObject]@{ Name = "Git";              Id = "Git.Git" }
)
foreach ($a in $Global:InstallCatalog) { [void]$AppInstList.Items.Add($a.Name) }

# Installed app list for Tab 1
$Global:AllInstalledApps = @()
$Script:SearchIsPlaceholder = $true

function Reload-AppList {
    $Global:AllInstalledApps = @(
        Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
            Where-Object { $_.NonRemovable -ne $true } |
            Select-Object -ExpandProperty Name |
            Sort-Object -Unique
    )
    Apply-AppFilter
}

function Apply-AppFilter {
    $filter = ""
    if (-not $Script:SearchIsPlaceholder) { $filter = $txtSearch.Text }
    $AppList.Items.Clear()
    foreach ($app in $Global:AllInstalledApps) {
        if ($filter -eq "" -or $app -like "*$filter*") {
            [void]$AppList.Items.Add($app)
        }
    }
    $lblAppCount.Text = "$($AppList.Items.Count) apps listed"
}

# Search placeholder behavior
$txtSearch.Add_GotFocus({
    if ($Script:SearchIsPlaceholder) {
        $Script:SearchIsPlaceholder = $false
        $txtSearch.Text      = ""
        $txtSearch.ForeColor = [System.Drawing.Color]::White
    }
})
$txtSearch.Add_LostFocus({
    if ($txtSearch.Text -eq "") {
        $Script:SearchIsPlaceholder = $true
        $txtSearch.Text      = "Search installed apps..."
        $txtSearch.ForeColor = [System.Drawing.Color]::Gray
    }
})
$txtSearch.Add_TextChanged({
    if (-not $Script:SearchIsPlaceholder) { Apply-AppFilter }
})

# ==============================================================================
# BUTTON LOGIC - TAB 1: OS CLEANUP
# ==============================================================================

$btnSelAll.Add_Click({
    for ($i = 0; $i -lt $AppList.Items.Count; $i++) { $AppList.SetItemChecked($i, $true) }
})
$btnDeselAll.Add_Click({
    for ($i = 0; $i -lt $AppList.Items.Count; $i++) { $AppList.SetItemChecked($i, $false) }
})
$btnRefresh.Add_Click({
    $lblAppCount.Text = "Refreshing..."
    $Form.Refresh()
    Reload-AppList
})

$btnRunCleanup.Add_Click({
    $selected = @($AppList.CheckedItems)
    if ($selected.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No apps selected.", "Nothing to do")
        return
    }

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "You are about to remove $($selected.Count) app(s). Proceed?",
        "Confirm Removal",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if ($confirm -ne "Yes") { return }

    $btnRunCleanup.Enabled = $false
    $btnRunCleanup.Text    = "Working, please wait..."
    $Form.Refresh()

    # Optional: flip IsInbox registry bit
    if ($chkUnlock.Checked) {
        $regBase = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Applications"
        if (Test-Path $regBase) {
            Get-ChildItem $regBase -ErrorAction SilentlyContinue | ForEach-Object {
                Set-ItemProperty -Path $_.PSPath -Name "IsInbox" -Value 0 -ErrorAction SilentlyContinue
            }
        }
    }

    foreach ($item in $selected) {
        Get-AppxPackage -AllUsers -Name $item -ErrorAction SilentlyContinue |
            Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -eq $item } |
            Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }

    # Re-register shell components
    if ($chkShell.Checked) {
        Get-AppxPackage -AllUsers *Windows.Search* -ErrorAction SilentlyContinue | ForEach-Object {
            Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue
        }
        Get-AppxPackage -AllUsers *ShellExperienceHost* -ErrorAction SilentlyContinue | ForEach-Object {
            Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue
        }
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    }

    Reload-AppList
    $btnRunCleanup.Enabled = $true
    $btnRunCleanup.Text    = "EXECUTE SELECTED APP REMOVAL"
    [System.Windows.Forms.MessageBox]::Show("Cleanup complete. List refreshed.", "Done")
})

# ==============================================================================
# BUTTON LOGIC - TAB 2: INSTALL APPS
# ==============================================================================

$btnInstSelAll.Add_Click({
    for ($i = 0; $i -lt $AppInstList.Items.Count; $i++) { $AppInstList.SetItemChecked($i, $true) }
})
$btnInstDeselAll.Add_Click({
    for ($i = 0; $i -lt $AppInstList.Items.Count; $i++) { $AppInstList.SetItemChecked($i, $false) }
})

$btnInstall.Add_Click({
    $selected = @($AppInstList.CheckedItems)
    if ($selected.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No apps selected.", "Nothing to do")
        return
    }

    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wingetCmd) {
        [System.Windows.Forms.MessageBox]::Show(
            "winget is not available on this system. Install App Installer from the Microsoft Store.",
            "winget Not Found",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return
    }

    $btnInstall.Enabled = $false
    $btnInstall.Text    = "Installing, please wait..."
    $Form.Refresh()

    foreach ($name in $selected) {
        $entry = $Global:InstallCatalog | Where-Object { $_.Name -eq $name }
        if ($entry) {
            winget install --id $entry.Id --silent --accept-package-agreements --accept-source-agreements 2>$null
        }
    }

    $btnInstall.Enabled = $true
    $btnInstall.Text    = "INSTALL SELECTED APPS"
    [System.Windows.Forms.MessageBox]::Show("Installation complete.", "Done")
})

# ==============================================================================
# BUTTON LOGIC - TAB 3: SYSTEM TWEAKS
# ==============================================================================

$btnRunTweaks.Add_Click({
    $btnRunTweaks.Enabled = $false
    $btnRunTweaks.Text    = "Working, please wait..."
    $Form.Refresh()

    # 1. System Restore Point
    if ($chkRestore.Checked) {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        try {
            Checkpoint-Computer -Description "WinCleanPro_v4_PreClean" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        } catch {
            $resp = [System.Windows.Forms.MessageBox]::Show(
                "Could not create restore point. Continue anyway?",
                "Restore Point Failed",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            if ($resp -ne "Yes") {
                $btnRunTweaks.Enabled = $true
                $btnRunTweaks.Text    = "APPLY SELECTED TWEAKS"
                return
            }
        }
    }

    # 2. Windows Update mode
    if ($radioUpdatePause.Checked) {
        $expiry = (Get-Date).AddDays(120).ToString("yyyy-MM-ddTHH:mm:ssZ")
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -Value $expiry -ErrorAction SilentlyContinue
    } elseif ($radioUpdateDisable.Checked) {
        Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
        Set-Service  -Name "wuauserv" -StartupType Disabled -ErrorAction SilentlyContinue
        $wuAU = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        if (-not (Test-Path $wuAU)) { New-Item -Path $wuAU -Force | Out-Null }
        Set-ItemProperty -Path $wuAU -Name "NoAutoUpdate" -Value 1 -Force
    }

    # 3. Block driver updates
    if ($chkNoDriverUpdate.Checked) {
        $wuPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
        if (-not (Test-Path $wuPath)) { New-Item -Path $wuPath -Force | Out-Null }
        Set-ItemProperty -Path $wuPath -Name "ExcludeWUDriversInQualityUpdate" -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" -Name "SearchOrderConfig" -Value 0
    }

    # 4. Remove Edge
    if ($chkEdge.Checked) {
        $edgeSetup = $null
        $edgeDir = "C:\Program Files (x86)\Microsoft\Edge\Application"
        if (Test-Path $edgeDir) {
            $edgeSetup = (Get-ChildItem $edgeDir -Filter "setup.exe" -Recurse -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
        }
        if ($edgeSetup) {
            Start-Process $edgeSetup -ArgumentList "--uninstall --system-level --verbose-logging --force-uninstall" -Wait
        }
    }

    # 5. Remove OneDrive
    if ($chkOneDrive.Checked) {
        taskkill /f /im OneDrive.exe 2>$null
        $odBit  = "System32"
        if ([Environment]::Is64BitOperatingSystem) { $odBit = "SysWOW64" }
        $odPath = Join-Path $env:SystemRoot "$odBit\OneDriveSetup.exe"
        if (Test-Path $odPath) { Start-Process $odPath -ArgumentList "/uninstall" -Wait }
    }

    # 6. Remove all provisioned packages
    if ($chkProvisionedAll.Checked) {
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
        }
    }

    # 7. Telemetry services
    if ($chkTelemetry.Checked) {
        $svcNames = @("DiagTrack", "dmwappushservice")
        foreach ($svc in $svcNames) {
            Stop-Service -Name $svc -ErrorAction SilentlyContinue
            Set-Service  -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        }
        $regData = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        if (-not (Test-Path $regData)) { New-Item -Path $regData -Force | Out-Null }
        Set-ItemProperty -Path $regData -Name "AllowTelemetry" -Value 0
    }

    # 8. Advertising ID
    if ($chkAdvID.Checked) {
        $advPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
        if (Test-Path $advPath) {
            Set-ItemProperty -Path $advPath -Name "Enabled" -Value 0 -ErrorAction SilentlyContinue
        }
    }

    # 9. Deep clean leftover app folders
    if ($chkDeepClean.Checked) {
        $t1 = "C:\Program Files\WindowsApps"
        $t2 = "C:\ProgramData\Microsoft\Windows\AppRepository"
        foreach ($p in @($t1, $t2)) {
            if (Test-Path $p) {
                takeown /f $p /r /d y 2>$null | Out-Null
                icacls $p /grant administrators:F /t 2>$null | Out-Null
                Get-ChildItem $p -Recurse -ErrorAction SilentlyContinue |
                    Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            }
        }
    }

    $btnRunTweaks.Enabled = $true
    $btnRunTweaks.Text    = "APPLY SELECTED TWEAKS"
    [System.Windows.Forms.MessageBox]::Show("All selected tweaks applied.", "Done")
})

$btnReboot.Add_Click({
    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "Reboot the system now?",
        "Confirm Reboot",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    if ($confirm -eq "Yes") { Restart-Computer }
})

# ==============================================================================
# BUTTON LOGIC - TAB 4: HARDWARE DIAGNOSTICS
# ==============================================================================

$btnDiag.Add_Click({
    $btnDiag.Enabled = $false
    $btnDiag.Text    = "Running..."
    $Form.Refresh()

    $nl = "`r`n"
    $r  = "==========================================================" + $nl
    $r += "  WinClean Pro v4.0 - Hardware Health Report" + $nl
    $r += "  Generated: " + (Get-Date -Format "yyyy-MM-dd  HH:mm:ss") + $nl
    $r += "  Machine:   " + $env:COMPUTERNAME + $nl
    $r += "==========================================================" + $nl + $nl

    $r += "--- CPU ---" + $nl
    $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue
    if ($cpu) {
        $r += "  Name   : " + $cpu.Name + $nl
        $r += "  Cores  : " + $cpu.NumberOfCores + "  /  Threads: " + $cpu.NumberOfLogicalProcessors + $nl
        $r += "  Speed  : " + $cpu.MaxClockSpeed + " MHz" + $nl
    }
    $r += $nl

    $r += "--- RAM ---" + $nl
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($os) {
        $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $freeGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedGB  = [math]::Round($totalGB - $freeGB, 2)
        $r += "  Total : " + $totalGB + " GB" + $nl
        $r += "  Used  : " + $usedGB + " GB" + $nl
        $r += "  Free  : " + $freeGB + " GB" + $nl
    }
    $r += $nl

    $r += "--- STORAGE (S.M.A.R.T.) ---" + $nl
    $disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
    if ($disks) {
        foreach ($d in $disks) {
            $sizeGB = [math]::Round($d.Size / 1GB, 1)
            $r += "  [$($d.DeviceId)] $($d.FriendlyName)  |  $($d.MediaType)  |  $sizeGB GB  |  Health: $($d.HealthStatus)  |  Status: $($d.OperationalStatus)" + $nl
        }
    } else {
        $r += "  Could not retrieve physical disk info." + $nl
    }
    $r += $nl

    $r += "--- DISK VOLUMES ---" + $nl
    $drives = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue
    foreach ($drv in $drives) {
        $usedDrv = [math]::Round($drv.Used / 1GB, 1)
        $freeDrv = [math]::Round($drv.Free / 1GB, 1)
        $r += "  [$($drv.Name):]  Used: $usedDrv GB  |  Free: $freeDrv GB" + $nl
    }
    $r += $nl

    $r += "--- BATTERY ---" + $nl
    $bat = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
    if ($bat) {
        $r += "  Name   : " + $bat.Name + $nl
        $r += "  Charge : " + $bat.EstimatedChargeRemaining + "%" + $nl
        $r += "  Status : " + $bat.Status + $nl
    } else {
        $r += "  No battery detected (Desktop / AIO)." + $nl
    }
    $r += $nl

    $r += "--- MOTHERBOARD ---" + $nl
    $mb = Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue
    if ($mb) {
        $r += "  Manufacturer : " + $mb.Manufacturer + $nl
        $r += "  Product      : " + $mb.Product + $nl
        $r += "  Serial       : " + $mb.SerialNumber + $nl
    }
    $r += $nl

    $r += "--- OS ---" + $nl
    if ($os) {
        $r += "  Edition : " + $os.Caption + $nl
        $r += "  Version : " + $os.Version + "  Build " + $os.BuildNumber + $nl
        $r += "  Arch    : " + $os.OSArchitecture + $nl
        $r += "  Boot    : " + $os.LastBootUpTime + $nl
    }

    $txtDiag.Text    = $r
    $btnDiag.Enabled = $true
    $btnDiag.Text    = "RUN HARDWARE HEALTH CHECK"
})

$btnSaveDiag.Add_Click({
    if ([string]::IsNullOrWhiteSpace($txtDiag.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Run the health check first.", "No Report")
        return
    }
    $stamp   = Get-Date -Format "yyyyMMdd_HHmmss"
    $outPath = Join-Path $env:USERPROFILE "Desktop\WinClean_HardwareDiag_$stamp.txt"
    $txtDiag.Text | Out-File $outPath -Encoding UTF8
    [System.Windows.Forms.MessageBox]::Show("Report saved to:`n$outPath", "Saved")
})

# ==============================================================================
# PROFILE SAVE / LOAD
# ==============================================================================

$btnSave.Add_Click({
    $profilePath = Join-Path $Script:ScriptDir "WinCleanProfile.json"
    $updateMode = "Default"
    if ($radioUpdatePause.Checked)   { $updateMode = "Pause" }
    if ($radioUpdateDisable.Checked) { $updateMode = "Disable" }

    $data = @{
        CleanupApps    = @($AppList.CheckedItems)
        InstallApps    = @($AppInstList.CheckedItems)
        UnlockApps     = $chkUnlock.Checked
        RepairShell    = $chkShell.Checked
        CreateRestore  = $chkRestore.Checked
        UpdateMode     = $updateMode
        BlockDrivers   = $chkNoDriverUpdate.Checked
        RemoveEdge     = $chkEdge.Checked
        RemoveOneDrive = $chkOneDrive.Checked
        RemoveProv     = $chkProvisionedAll.Checked
        Telemetry      = $chkTelemetry.Checked
        AdvID          = $chkAdvID.Checked
        DeepClean      = $chkDeepClean.Checked
    }
    $data | ConvertTo-Json -Depth 5 | Out-File $profilePath -Encoding UTF8
    $lblProfileStatus.Text      = "Saved: WinCleanProfile.json"
    $lblProfileStatus.ForeColor = [System.Drawing.Color]::LightGreen
    [System.Windows.Forms.MessageBox]::Show("Profile saved to:`n$profilePath", "Profile Saved")
})

$btnLoad.Add_Click({
    $profilePath = Join-Path $Script:ScriptDir "WinCleanProfile.json"
    if (-not (Test-Path $profilePath)) {
        [System.Windows.Forms.MessageBox]::Show("No profile found at:`n$profilePath", "Not Found")
        return
    }
    $d = Get-Content $profilePath -Raw | ConvertFrom-Json

    for ($i = 0; $i -lt $AppList.Items.Count; $i++) {
        $AppList.SetItemChecked($i, ($d.CleanupApps -contains $AppList.Items[$i]))
    }
    for ($i = 0; $i -lt $AppInstList.Items.Count; $i++) {
        $AppInstList.SetItemChecked($i, ($d.InstallApps -contains $AppInstList.Items[$i]))
    }

    $chkUnlock.Checked         = [bool]$d.UnlockApps
    $chkShell.Checked          = [bool]$d.RepairShell
    $chkRestore.Checked        = [bool]$d.CreateRestore
    $chkNoDriverUpdate.Checked = [bool]$d.BlockDrivers
    $chkEdge.Checked           = [bool]$d.RemoveEdge
    $chkOneDrive.Checked       = [bool]$d.RemoveOneDrive
    $chkProvisionedAll.Checked = [bool]$d.RemoveProv
    $chkTelemetry.Checked      = [bool]$d.Telemetry
    $chkAdvID.Checked          = [bool]$d.AdvID
    $chkDeepClean.Checked      = [bool]$d.DeepClean

    switch ($d.UpdateMode) {
        "Pause"   { $radioUpdatePause.Checked   = $true }
        "Disable" { $radioUpdateDisable.Checked = $true }
        default   { $radioUpdateDefault.Checked = $true }
    }

    $lblProfileStatus.Text      = "Loaded: WinCleanProfile.json"
    $lblProfileStatus.ForeColor = [System.Drawing.Color]::LightBlue
})

# ==============================================================================
# LAUNCH
# ==============================================================================
try {
    [void]$Form.ShowDialog()
} catch {
    [System.Windows.Forms.MessageBox]::Show(
        "Fatal error: $($_.Exception.Message)",
        "WinClean Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
}
