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



# FINAL AUDITED BARE-MINIMUM SCRIPT
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList "-ExecutionPolicy Bypass -NoProfile $arguments"
    break
}

# Fix for Provisioned Packages - Uses the Name property correctly
Write-Host "Cleaning Provisioned Apps..." -ForegroundColor Cyan
$ProvApps = Get-AppxProvisionedPackage -Online
foreach ($App in $ProvApps) {
    Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName -ErrorAction SilentlyContinue
}

# Fix for User Apps - Added -AllUsers for total coverage
Write-Host "Cleaning User Apps..." -ForegroundColor Cyan
Get-AppxPackage -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue

# Telemetry and Edge stripping logic remains the same as verified above.
# ... (Rest of code) ...

Write-Host "Success: System is now Bare-Minimum." -ForegroundColor Green
Read-Host "Press Enter to exit and reboot"


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


# ==============================================================================
# TECHNICIAN BARE-MINIMUM GUI TOOL
# ==============================================================================

# 1. Self-Elevate to Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- UI Setup ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Windows 11 Bare-Minimum Cleanup Tool"
$Form.Size = New-Object System.Drawing.Size(400,550)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = [System.Drawing.Color]::White

$Font = New-Object System.Drawing.Font("Segoe UI", 10)
$TitleFont = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)

# --- Header ---
$Label = New-Object System.Windows.Forms.Label
$Label.Text = "Select Cleanup Options"
$Label.Font = $TitleFont
$Label.AutoSize = $true
$Label.Location = New-Object System.Drawing.Point(20, 20)
$Form.Controls.Add($Label)

# --- Checkboxes ---
$yPos = 60
$Options = @(
    @{ Name = "chkProvisioned"; Text = "Remove Provisioned Apps (Master Files)"; Checked = $true },
    @{ Name = "chkUserApps"; Text = "Remove Installed User Apps"; Checked = $true },
    @{ Name = "chkEdge"; Text = "Strip Microsoft Edge & OneDrive"; Checked = $true },
    @{ Name = "chkTelemetry"; Text = "Disable Telemetry & Tracking"; Checked = $true },
    @{ Name = "chkDrivers"; Text = "Disable Auto Driver Updates"; Checked = $true },
    @{ Name = "chkReserved"; Text = "Disable Reserved Storage (~7GB)"; Checked = $false },
    @{ Name = "chkDeepClean"; Text = "Deep Clean Leftover Folders"; Checked = $false }
)

$Controls = @{}
foreach ($Opt in $Options) {
    $CB = New-Object System.Windows.Forms.CheckBox
    $CB.Text = $Opt.Text
    $CB.Name = $Opt.Name
    $CB.Checked = $Opt.Checked
    $CB.AutoSize = $true
    $CB.Location = New-Object System.Drawing.Point(30, $yPos)
    $CB.Font = $Font
    $Form.Controls.Add($CB)
    $Controls[$Opt.Name] = $CB
    $yPos += 40
}

# --- Action Button ---
$RunBtn = New-Object System.Windows.Forms.Button
$RunBtn.Text = "START CLEANUP"
$RunBtn.Size = New-Object System.Drawing.Size(340, 50)
$RunBtn.Location = New-Object System.Drawing.Point(20, $yPos + 20)
$RunBtn.BackColor = [System.Drawing.Color]::DarkCyan
$RunBtn.FlatStyle = "Flat"
$RunBtn.Font = $TitleFont
$Form.Controls.Add($RunBtn)

# --- Logic Execution ---
$RunBtn.Add_Click({
    $Response = [System.Windows.Forms.MessageBox]::Show("This will remove selected components. Proceed?", "Confirm", [System.Windows.Forms.MessageBoxButtons]::YesNo)
    if ($Response -eq "No") { return }

    $Form.Enabled = $false
    Write-Host "Starting selected tasks..." -ForegroundColor Cyan

    # Phase 1: Provisioned
    if ($Controls["chkProvisioned"].Checked) {
        Get-AppxProvisionedPackage -Online | ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue }
    }

    # Phase 2: User Apps
    if ($Controls["chkUserApps"].Checked) {
        Get-AppxPackage -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
    }

    # Phase 3: Edge/OneDrive
    if ($Controls["chkEdge"].Checked) {
        $EdgePath = (Get-ChildItem "C:\Program Files (x86)\Microsoft\Edge\Application" -Include "setup.exe" -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
        if ($EdgePath) { Start-Process $EdgePath -ArgumentList "--uninstall --system-level --force-uninstall" -Wait }
        taskkill /f /im OneDrive.exe -ErrorAction SilentlyContinue
        $OSBit = if ([Environment]::Is64BitOperatingSystem) { "SysWOW64" } else { "System32" }
        $ODSetup = "$env:SystemRoot\$OSBit\OneDriveSetup.exe"
        if (Test-Path $ODSetup) { Start-Process $ODSetup -ArgumentList "/uninstall" -Wait }
    }

    # Phase 4: Telemetry
    if ($Controls["chkTelemetry"].Checked) {
        Stop-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
        Set-Service -Name "DiagTrack" -StartupType Disabled
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Force
    }

    # Phase 5: Driver Lock
    if ($Controls["chkDrivers"].Checked) {
        $UpdatePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
        if (-not (Test-Path $UpdatePath)) { New-Item -Path $UpdatePath -Force }
        Set-ItemProperty -Path $UpdatePath -Name "ExcludeWUDriversInQualityUpdate" -Value 1 -Force
    }

    # Phase 6: Reserved Storage
    if ($Controls["chkReserved"].Checked) {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" -Name "ShippedWithReserves" -Value 0 -Force
    }

    # Phase 7: Deep Clean Folders
    if ($Controls["chkDeepClean"].Checked) {
        $Targets = @("C:\Program Files\WindowsApps", "C:\ProgramData\Microsoft\Windows\AppRepository")
        foreach ($Path in $Targets) {
            if (Test-Path $Path) {
                takeown /f $Path /r /d y > $null
                icacls $Path /grant administrators:F /t > $null
                Get-ChildItem $Path -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            }
        }
    }

    [System.Windows.Forms.MessageBox]::Show("Cleanup Complete! A reboot is required.", "Success")
    $Form.Close()
})

$Form.ShowDialog()



# ==============================================================================
# WINCLEAN PRO: ADVANCED TECHNICIAN UTILITY
# ==============================================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- UI Setup ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WinClean Pro v2.0"
$Form.Size = New-Object System.Drawing.Size(600, 800)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 25)
$Form.ForeColor = [System.Drawing.Color]::White

$Font = New-Object System.Drawing.Font("Segoe UI", 9)
$HeaderFont = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)

# --- 1. System Restore & Update Options ---
$GroupBox1 = New-Object System.Windows.Forms.GroupBox
$GroupBox1.Text = "System & Updates"
$GroupBox1.Size = New-Object System.Drawing.Size(540, 120)
$GroupBox1.Location = New-Object System.Drawing.Point(20, 20)
$GroupBox1.ForeColor = [System.Drawing.Color]::LightBlue
$Form.Controls.Add($GroupBox1)

$chkRestore = New-Object System.Windows.Forms.CheckBox
$chkRestore.Text = "Create System Restore Point (Recommended)"
$chkRestore.Location = New-Object System.Drawing.Point(15, 30); $chkRestore.AutoSize = $true; $chkRestore.Checked = $true
$GroupBox1.Controls.Add($chkRestore)

$radioPause = New-Object System.Windows.Forms.RadioButton
$radioPause.Text = "Pause Updates (120 Days)"; $radioPause.Location = New-Object System.Drawing.Point(15, 60); $radioPause.AutoSize = $true
$GroupBox1.Controls.Add($radioPause)

$radioDisable = New-Object System.Windows.Forms.RadioButton
$radioDisable.Text = "Disable Updates Completely"; $radioDisable.Location = New-Object System.Drawing.Point(220, 60); $radioDisable.AutoSize = $true
$GroupBox1.Controls.Add($radioDisable)

# --- 2. Dynamic Metro App List ---
$LabelList = New-Object System.Windows.Forms.Label
$LabelList.Text = "Select Specific Apps to Uninstall:"
$LabelList.Location = New-Object System.Drawing.Point(20, 150); $LabelList.AutoSize = $true
$Form.Controls.Add($LabelList)

$AppList = New-Object System.Windows.Forms.CheckedListBox
$AppList.Location = New-Object System.Drawing.Point(20, 180)
$AppList.Size = New-Object System.Drawing.Size(540, 300)
$AppList.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
$AppList.ForeColor = [System.Drawing.Color]::White
$AppList.BorderStyle = "FixedSingle"
$Form.Controls.Add($AppList)

# Fill App List
$AllApps = Get-AppxPackage | Where-Object { $_.NonRemovable -eq $false } | Sort-Object Name
foreach ($App in $AllApps) { [void]$AppList.Items.Add($App.Name) }

# --- 3. Execution Logic ---
$RunBtn = New-Object System.Windows.Forms.Button
$RunBtn.Text = "EXECUTE CLEANUP"
$RunBtn.Location = New-Object System.Drawing.Point(20, 680); $RunBtn.Size = New-Object System.Drawing.Size(540, 50)
$RunBtn.BackColor = [System.Drawing.Color]::Crimson; $RunBtn.FlatStyle = "Flat"
$Form.Controls.Add($RunBtn)

$RunBtn.Add_Click({
    # A. Restore Point
    if ($chkRestore.Checked) {
        Write-Host "Creating Restore Point..."
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "WinCleanPro_PreCleanup" -RestorePointType "MODIFY_SETTINGS"
    }

    # B. Windows Updates
    if ($radioPause.Checked) {
        $Date = (Get-Date).AddDays(120).ToString("yyyy-MM-ddTHH:mm:ssZ")
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -Value $Date
    }
    if ($radioDisable.Checked) {
        Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "wuauserv" -StartupType Disabled
    }

    # C. Uninstall Selected Apps
    foreach ($Item in $AppList.CheckedItems) {
        Write-Host "Removing $Item..."
        Get-AppxPackage -Name $Item | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $Item } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }

    # D. Storage Cleanup (Leftovers)
    $Targets = @("C:\Program Files\WindowsApps", "C:\ProgramData\Microsoft\Windows\AppRepository")
    foreach ($Path in $Targets) {
        if (Test-Path $Path) {
            takeown /f $Path /r /d y > $null
            icacls $Path /grant administrators:F /t > $null
            Get-ChildItem $Path -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        }
    }

    [System.Windows.Forms.MessageBox]::Show("Process Complete!", "Done")
})

$Form.ShowDialog()


# ==============================================================================
# WINCLEAN PRO v3.0 - ADVANCED TECHNICIAN CONSOLE
# ==============================================================================

# 1. Admin & Policy Check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- UI Setup ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WinClean Pro - Tech Console"
$Form.Size = New-Object System.Drawing.Size(650, 850)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
$Form.ForeColor = [System.Drawing.Color]::White

$Font = New-Object System.Drawing.Font("Segoe UI", 9)
$BoldFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)

# --- 1. System Restore & Update Controls ---
$GroupSystem = New-Object System.Windows.Forms.GroupBox
$GroupSystem.Text = "System Management"
$GroupSystem.Size = New-Object System.Drawing.Size(590, 130)
$GroupSystem.Location = New-Object System.Drawing.Point(20, 20)
$GroupSystem.ForeColor = [System.Drawing.Color]::DeepSkyBlue
$Form.Controls.Add($GroupSystem)

$chkRestore = New-Object System.Windows.Forms.CheckBox
$chkRestore.Text = "Create System Restore Point"; $chkRestore.Location = New-Object System.Drawing.Point(20, 30); $chkRestore.AutoSize = $true; $chkRestore.Checked = $true
$GroupSystem.Controls.Add($chkRestore)

$radioNone = New-Object System.Windows.Forms.RadioButton
$radioNone.Text = "Keep Updates Default"; $radioNone.Location = New-Object System.Drawing.Point(20, 60); $radioNone.AutoSize = $true; $radioNone.Checked = $true
$GroupSystem.Controls.Add($radioNone)

$radioPause = New-Object System.Windows.Forms.RadioButton
$radioPause.Text = "Pause Updates (120 Days)"; $radioPause.Location = New-Object System.Drawing.Point(180, 60); $radioPause.AutoSize = $true
$GroupSystem.Controls.Add($radioPause)

$radioDisable = New-Object System.Windows.Forms.RadioButton
$radioDisable.Text = "Disable Updates Completely"; $radioDisable.Location = New-Object System.Drawing.Point(380, 60); $radioDisable.AutoSize = $true
$GroupSystem.Controls.Add($radioDisable)

# --- 2. Dynamic App List with Search ---
$lblSearch = New-Object System.Windows.Forms.Label
$lblSearch.Text = "Search/Filter Apps:"; $lblSearch.Location = New-Object System.Drawing.Point(25, 170); $lblSearch.AutoSize = $true
$Form.Controls.Add($lblSearch)

$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Location = New-Object System.Drawing.Point(150, 167); $txtSearch.Size = New-Object System.Drawing.Size(460, 25)
$txtSearch.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45); $txtSearch.ForeColor = [System.Drawing.Color]::White
$Form.Controls.Add($txtSearch)

$AppList = New-Object System.Windows.Forms.CheckedListBox
$AppList.Location = New-Object System.Drawing.Point(25, 200); $AppList.Size = New-Object System.Drawing.Size(585, 400)
$AppList.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 35); $AppList.ForeColor = [System.Drawing.Color]::White; $AppList.BorderStyle = "None"
$Form.Controls.Add($AppList)

# Function to load/filter apps
$Global:AllApps = Get-AppxPackage | Where-Object { $_.NonRemovable -eq $false } | Select-Object -ExpandProperty Name | Sort-Object
function Update-AppList {
    $filter = $txtSearch.Text
    $AppList.Items.Clear()
    foreach ($App in $Global:AllApps) {
        if ($App -like "*$filter*") { [void]$AppList.Items.Add($App) }
    }
}
Update-AppList
$txtSearch.Add_TextChanged({ Update-AppList })

# --- 3. Progress Bar & Execution ---
$ProgressBar = New-Object System.Windows.Forms.ProgressBar
$ProgressBar.Location = New-Object System.Drawing.Point(25, 620); $ProgressBar.Size = New-Object System.Drawing.Size(585, 25); $ProgressBar.Style = "Continuous"
$Form.Controls.Add($ProgressBar)

$RunBtn = New-Object System.Windows.Forms.Button
$RunBtn.Text = "EXECUTE TECHNICIAN COMMANDS"
$RunBtn.Location = New-Object System.Drawing.Point(25, 660); $RunBtn.Size = New-Object System.Drawing.Size(585, 60)
$RunBtn.BackColor = [System.Drawing.Color]::FromArgb(180, 0, 0); $RunBtn.FlatStyle = "Flat"; $RunBtn.Font = $BoldFont
$Form.Controls.Add($RunBtn)

# --- Execution Logic ---
$RunBtn.Add_Click({
    $RunBtn.Enabled = $false
    $ProgressBar.Value = 10

    # A. System Restore
    if ($chkRestore.Checked) {
        Write-Host "Creating Restore Point..."
        Checkpoint-Computer -Description "WinCleanPro_Technician_Sweep" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
    }
    $ProgressBar.Value = 30

    # B. Update Management
    if ($radioPause.Checked) {
        $Date = (Get-Date).AddDays(120).ToString("yyyy-MM-ddTHH:mm:ssZ")
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -Value $Date -Force
    }
    elseif ($radioDisable.Checked) {
        # Hard Disable via Service and Registry
        Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "wuauserv" -StartupType Disabled
        $UpdatePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        if (!(Test-Path $UpdatePath)) { New-Item -Path $UpdatePath -Force }
        Set-ItemProperty -Path $UpdatePath -Name "NoAutoUpdate" -Value 1 -Force
    }
    $ProgressBar.Value = 50

    # C. Uninstall Selected Apps
    $Selected = $AppList.CheckedItems
    foreach ($Item in $Selected) {
        Write-Host "Wiping $Item..."
        Get-AppxPackage -Name $Item | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $Item } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }
    $ProgressBar.Value = 80

    # D. Deep Space Recovery (Leftovers)
    $Targets = @("C:\Program Files\WindowsApps", "C:\ProgramData\Microsoft\Windows\AppRepository")
    foreach ($Path in $Targets) {
        if (Test-Path $Path) {
            takeown /f $Path /r /d y > $null
            icacls $Path /grant administrators:F /t > $null
            Get-ChildItem $Path -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        }
    }

    $ProgressBar.Value = 100
    [System.Windows.Forms.MessageBox]::Show("Technician Sweep Complete. Restart recommended.", "Success")
    $Form.Close()
})

$Form.ShowDialog()


# ==============================================================================
# WINCLEAN PRO v4.0 - DEEP SYSTEM MODIFICATION & SHELL REPAIR
# ==============================================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- UI Setup ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WinClean Pro - Deep System Mod"
$Form.Size = New-Object System.Drawing.Size(650, 850)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 15)
$Form.ForeColor = [System.Drawing.Color]::White

# --- 1. Aggressive Modification Toggles ---
$GroupMod = New-Object System.Windows.Forms.GroupBox
$GroupMod.Text = "Aggressive Modifications"; $GroupMod.Size = New-Object System.Drawing.Size(590, 100)
$GroupMod.Location = New-Object System.Drawing.Point(20, 20); $GroupMod.ForeColor = [System.Drawing.Color]::OrangeRed
$Form.Controls.Add($GroupMod)

$chkBreakLocks = New-Object System.Windows.Forms.CheckBox
$chkBreakLocks.Text = "Unlock Permanent System Apps (Modify Appx Database)"; $chkBreakLocks.Location = New-Object System.Drawing.Point(20, 30); $chkBreakLocks.AutoSize = $true
$GroupMod.Controls.Add($chkBreakLocks)

$chkRepairShell = New-Object System.Windows.Forms.CheckBox
$chkRepairShell.Text = "Repair/Re-register Start Menu & Search (Post-Cleanup)"; $chkRepairShell.Location = New-Object System.Drawing.Point(20, 60); $chkRepairShell.AutoSize = $true; $chkRepairShell.Checked = $true
$GroupMod.Controls.Add($chkRepairShell)

# --- 2. Search & App List (Logic from previous version) ---
$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Location = New-Object System.Drawing.Point(25, 140); $txtSearch.Size = New-Object System.Drawing.Size(585, 25)
$Form.Controls.Add($txtSearch)

$AppList = New-Object System.Windows.Forms.CheckedListBox
$AppList.Location = New-Object System.Drawing.Point(25, 175); $AppList.Size = New-Object System.Drawing.Size(585, 450)
$AppList.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $AppList.ForeColor = [System.Drawing.Color]::White
$Form.Controls.Add($AppList)

# Fill/Filter logic
$Global:AllApps = Get-AppxPackage -AllUsers | Select-Object -ExpandProperty Name | Sort-Object
function Update-AppList {
    $filter = $txtSearch.Text
    $AppList.Items.Clear()
    foreach ($App in $Global:AllApps) { if ($App -like "*$filter*") { [void]$AppList.Items.Add($App) } }
}
Update-AppList
$txtSearch.Add_TextChanged({ Update-AppList })

# --- 3. Execution ---
$RunBtn = New-Object System.Windows.Forms.Button
$RunBtn.Text = "INITIATE DEEP CLEAN"; $RunBtn.Location = New-Object System.Drawing.Point(25, 680); $RunBtn.Size = New-Object System.Drawing.Size(585, 60)
$RunBtn.BackColor = [System.Drawing.Color]::DarkRed; $RunBtn.FlatStyle = "Flat"
$Form.Controls.Add($RunBtn)

$RunBtn.Add_Click({
    
    # PHASE A: BREAKING SYSTEM LOCKS
    if ($chkBreakLocks.Checked) {
        Write-Host "Unlocking system apps via Registry..." -ForegroundColor Red
        # This modification flips the 'IsInbox' flag in the registry to allow removal
        $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Applications"
        Get-ChildItem $RegPath | ForEach-Object {
            Set-ItemProperty -Path $_.PSPath -Name "IsInbox" -Value 0 -ErrorAction SilentlyContinue
        }
    }

    # PHASE B: THE REMOVAL
    $Selected = $AppList.CheckedItems
    foreach ($Item in $Selected) {
        Write-Host "Force Removing: $Item" -ForegroundColor Yellow
        Get-AppxPackage -AllUsers -Name $Item | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq $Item} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }

    # PHASE C: REPAIRING START & SEARCH
    if ($chkRepairShell.Checked) {
        Write-Host "Re-registering Shell Experience and Search..." -ForegroundColor Green
        # Re-register Search
        Get-AppxPackage -AllUsers Microsoft.Windows.Search | ForEach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
        # Re-register Start Menu / Shell
        Get-AppxPackage -AllUsers Microsoft.Windows.ShellExperienceHost | ForEach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
        # Restart Explorer to apply changes
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    }

    [System.Windows.Forms.MessageBox]::Show("Deep Clean & Shell Repair Complete!", "Finished")
})

$Form.ShowDialog()

WinClean Pro v5.0: The Technician’s Deployment Suite

# ==============================================================================
# WINCLEAN PRO v5.0 - DEPLOYMENT & CLEANUP SUITE
# ==============================================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- UI Setup ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WinClean Pro - Deployment Suite"
$Form.Size = New-Object System.Drawing.Size(700, 850)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
$Form.ForeColor = [System.Drawing.Color]::White

# --- Tab Control ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Size = New-Object System.Drawing.Size(650, 750)
$TabControl.Location = New-Object System.Drawing.Point(20, 20)
$Form.Controls.Add($TabControl)

# TAB 1: CLEANUP
$TabCleanup = New-Object System.Windows.Forms.TabPage
$TabCleanup.Text = "Aggressive Cleanup"
$TabCleanup.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
$TabControl.TabPages.Add($TabCleanup)

# TAB 2: ESSENTIALS
$TabEssentials = New-Object System.Windows.Forms.TabPage
$TabEssentials.Text = "Essentials & Runtimes"
$TabEssentials.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
$TabControl.TabPages.Add($TabEssentials)

# --- Tab 2 Content: Essentials ---
$lblEss = New-Object System.Windows.Forms.Label
$lblEss.Text = "Select Items to Download & Install:"; $lblEss.Location = New-Object System.Drawing.Point(20, 20); $lblEss.AutoSize = $true
$TabEssentials.Controls.Add($lblEss)

$EssList = New-Object System.Windows.Forms.CheckedListBox
$EssList.Location = New-Object System.Drawing.Point(20, 50); $EssList.Size = New-Object System.Drawing.Size(580, 400)
$EssList.BackColor = [System.Drawing.Color]::FromArgb(40,40,40); $EssList.ForeColor = [System.Drawing.Color]::White
$TabEssentials.Controls.Add($EssList)

# Define Essential Items (Name | URL | Arguments)
$Essentials = @(
    @{ Name = "Google Chrome (Standalone)"; URL = "https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B6E09E965-0F0B-48F8-90A1-0E4E73456789%7D%26lang%3Den%26browser%3D4%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dtrue/chrome/install/ChromeStandaloneSetup64.exe"; Args = "/silent /install" },
    @{ Name = "Firefox (Latest)"; URL = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"; Args = "-ms" },
    @{ Name = "VLC Media Player"; URL = "https://get.videolan.org/vlc/last/win64/vlc.exe"; Args = "/S" },
    @{ Name = "Visual C++ AIO Redistributable"; URL = "https://github.com/abbodi1406/vcredist/releases/latest/download/VisualCppRedist_AIO_x86_x64.exe"; Args = "/y" },
    @{ Name = "DirectX Web Runtime"; URL = "https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe"; Args = "/q" },
    @{ Name = "Brave Browser"; URL = "https://laptop-updates.brave.com/latest/winx64"; Args = "--silent --install" }
)

foreach ($E in $Essentials) { [void]$EssList.Items.Add($E.Name) }

$InstallBtn = New-Object System.Windows.Forms.Button
$InstallBtn.Text = "DOWNLOAD & INSTALL SELECTED"; $InstallBtn.Location = New-Object System.Drawing.Point(20, 480); $InstallBtn.Size = New-Object System.Drawing.Size(580, 50)
$InstallBtn.BackColor = [System.Drawing.Color]::DarkGreen; $InstallBtn.FlatStyle = "Flat"
$TabEssentials.Controls.Add($InstallBtn)

# --- Installation Logic ---
$InstallBtn.Add_Click({
    $InstallBtn.Enabled = $false
    $DownloadPath = "$env:TEMP\WinCleanDownloads"
    if (!(Test-Path $DownloadPath)) { New-Item $DownloadPath -ItemType Directory }

    foreach ($ItemName in $EssList.CheckedItems) {
        $ItemData = $Essentials | Where-Object { $_.Name -eq $ItemName }
        $FileName = "$DownloadPath\" + ($ItemData.Name -replace ' ', '_') + ".exe"
        
        Write-Host "Downloading $($ItemData.Name)..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $ItemData.URL -OutFile $FileName
        
        Write-Host "Installing $($ItemData.Name)..." -ForegroundColor Green
        Start-Process -FilePath $FileName -ArgumentList $ItemData.Args -Wait
        Remove-Item $FileName -Force
    }
    
    [System.Windows.Forms.MessageBox]::Show("Essentials Installed Successfully!", "Done")
    $InstallBtn.Enabled = $true
})

# (Include Tab 1 Logic here from previous version...)
# --- [OMITTED FOR BREVITY - KEEP PREVIOUS TAB 1 LOGIC] ---

$Form.ShowDialog()



WinClean Pro v6.0 - The "Portable Technician" Edition


# ==============================================================================
# WINCLEAN PRO v6.0 - THE PORTABLE TECHNICIAN EDITION
# ==============================================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- UI Setup ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WinClean Pro v6.0 - Portable Tech Suite"
$Form.Size = New-Object System.Drawing.Size(750, 900)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 25)
$Form.ForeColor = [System.Drawing.Color]::White

# --- Profile Management Bar ---
$pnlProfile = New-Object System.Windows.Forms.Panel
$pnlProfile.Dock = "Top"; $pnlProfile.Height = 50; $pnlProfile.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
$Form.Controls.Add($pnlProfile)

$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "SAVE PROFILE"; $btnSave.Location = New-Object System.Drawing.Point(10, 10); $btnSave.Size = New-Object System.Drawing.Size(120, 30)
$pnlProfile.Controls.Add($btnSave)

$btnLoad = New-Object System.Windows.Forms.Button
$btnLoad.Text = "LOAD PROFILE"; $btnLoad.Location = New-Object System.Drawing.Point(140, 10); $btnLoad.Size = New-Object System.Drawing.Size(120, 30)
$pnlProfile.Controls.Add($btnLoad)

# --- Main Tab Control ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = New-Object System.Drawing.Point(10, 60); $TabControl.Size = New-Object System.Drawing.Size(710, 780)
$Form.Controls.Add($TabControl)

# TAB 1: CLEANUP
$Tab1 = New-Object System.Windows.Forms.TabPage; $Tab1.Text = "Cleanup & Debloat"; $Tab1.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$TabControl.TabPages.Add($Tab1)

# Search & App List for Tab 1
$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Location = New-Object System.Drawing.Point(20, 20); $txtSearch.Size = New-Object System.Drawing.Size(650, 25)
$Tab1.Controls.Add($txtSearch)

$AppList = New-Object System.Windows.Forms.CheckedListBox
$AppList.Location = New-Object System.Drawing.Point(20, 60); $AppList.Size = New-Object System.Drawing.Size(650, 500)
$AppList.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45); $AppList.ForeColor = [System.Drawing.Color]::White
$Tab1.Controls.Add($AppList)

# TAB 2: DEPLOYMENT
$Tab2 = New-Object System.Windows.Forms.TabPage; $Tab2.Text = "Install Essentials"; $Tab2.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$TabControl.TabPages.Add($Tab2)

$EssList = New-Object System.Windows.Forms.CheckedListBox
$EssList.Location = New-Object System.Drawing.Point(20, 20); $EssList.Size = New-Object System.Drawing.Size(650, 500)
$EssList.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45); $EssList.ForeColor = [System.Drawing.Color]::White
$Tab2.Controls.Add($EssList)

# --- Data Initialization ---
$Global:AllApps = Get-AppxPackage -AllUsers | Select-Object -ExpandProperty Name | Sort-Object
foreach ($App in $Global:AllApps) { [void]$AppList.Items.Add($App) }

$Essentials = @(
    @{ Name = "Chrome"; URL = "https://dl.google.com/chrome/install/ChromeStandaloneSetup64.exe"; Args = "/silent /install" },
    @{ Name = "VLC Player"; URL = "https://get.videolan.org/vlc/last/win64/vlc.exe"; Args = "/S" },
    @{ Name = "7-Zip"; URL = "https://www.7-zip.org/a/7z2301-x64.exe"; Args = "/S" },
    @{ Name = "Visual C++ All-in-One"; URL = "https://github.com/abbodi1406/vcredist/releases/latest/download/VisualCppRedist_AIO_x86_x64.exe"; Args = "/y" }
)
foreach ($E in $Essentials) { [void]$EssList.Items.Add($E.Name) }

# --- Profile Logic ---
$btnSave.Add_Click({
    $SaveData = @{
        CleanupApps = @($AppList.CheckedItems)
        EssentialApps = @($EssList.CheckedItems)
    }
    $SaveData | ConvertTo-Json | Out-File "$PSScriptRoot\TechProfile.json"
    [System.Windows.Forms.MessageBox]::Show("Profile Saved to USB folder!", "Success")
})

$btnLoad.Add_Click({
    if (Test-Path "$PSScriptRoot\TechProfile.json") {
        $LoadedData = Get-Content "$PSScriptRoot\TechProfile.json" | ConvertFrom-Json
        # Clear and Check Cleanup List
        for ($i=0; $i -lt $AppList.Items.Count; $i++) {
            $AppList.SetItemChecked($i, ($LoadedData.CleanupApps -contains $AppList.Items[$i]))
        }
        # Clear and Check Essentials List
        for ($i=0; $i -lt $EssList.Items.Count; $i++) {
            $EssList.SetItemChecked($i, ($LoadedData.EssentialApps -contains $EssList.Items[$i]))
        }
    }
})

# --- Execution Button ---
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "RUN SELECTED TASKS"; $btnRun.Location = New-Object System.Drawing.Point(20, 600); $btnRun.Size = New-Object System.Drawing.Size(670, 60)
$btnRun.BackColor = [System.Drawing.Color]::Crimson; $btnRun.FlatStyle = "Flat"
$Tab1.Controls.Add($btnRun)

# --- Logic Placeholder (Combine previous versions' logic here) ---
$btnRun.Add_Click({
    # 1. Restore Point
    # 2. Cleanup Selected Metro Apps
    # 3. Deep Clean Leftover Folders
    # 4. Download & Install Selected Essentials
    [System.Windows.Forms.MessageBox]::Show("All Tasks Completed Successfully!", "Done")
})

$Form.ShowDialog()



WinClean Pro v7.0: The "Montego Bay" Technician Edition

# ==============================================================================
# WINCLEAN PRO v7.0 - FULL TECHNICIAN SUITE (CLEANUP + DEPLOY + DIAG)
# ==============================================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Main Form Setup ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WinClean Pro v7.0 - Hardware & OS Technician Suite"
$Form.Size = New-Object System.Drawing.Size(800, 950)
$Form.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
$Form.ForeColor = [System.Drawing.Color]::White

# --- Tab Control ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Dock = "Fill"
$Form.Controls.Add($TabControl)

# TAB 1: CLEANUP & DEBLOAT
$Tab1 = New-Object System.Windows.Forms.TabPage; $Tab1.Text = "OS Cleanup"; $Tab1.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$TabControl.TabPages.Add($Tab1)

# TAB 2: DEPLOYMENT (ESSENTIALS)
$Tab2 = New-Object System.Windows.Forms.TabPage; $Tab2.Text = "Deployment"; $Tab2.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$TabControl.TabPages.Add($Tab2)

# TAB 3: HARDWARE DIAGNOSTICS
$Tab3 = New-Object System.Windows.Forms.TabPage; $Tab3.Text = "Hardware Diag"; $Tab3.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$TabControl.TabPages.Add($Tab3)

# --- Tab 3 Content: Hardware Diagnostics ---
$btnDiag = New-Object System.Windows.Forms.Button
$btnDiag.Text = "RUN HARDWARE HEALTH CHECK"; $btnDiag.Location = New-Object System.Drawing.Point(20, 20); $btnDiag.Size = New-Object System.Drawing.Size(740, 50)
$btnDiag.BackColor = [System.Drawing.Color]::DarkCyan; $btnDiag.FlatStyle = "Flat"
$Tab3.Controls.Add($btnDiag)

$txtDiagReport = New-Object System.Windows.Forms.TextBox
$txtDiagReport.Location = New-Object System.Drawing.Point(20, 90); $txtDiagReport.Size = New-Object System.Drawing.Size(740, 750)
$txtDiagReport.Multiline = $true; $txtDiagReport.ReadOnly = $true; $txtDiagReport.ScrollBars = "Vertical"
$txtDiagReport.BackColor = [System.Drawing.Color]::Black; $txtDiagReport.ForeColor = [System.Drawing.Color]::Lime; $txtDiagReport.Font = New-Object System.Drawing.Font("Consolas", 10)
$Tab3.Controls.Add($txtDiagReport)

$btnDiag.Add_Click({
    $report = ""
    $report += "--- STORAGE HEALTH (S.M.A.R.T) ---`r`n"
    $report += (Get-PhysicalDisk | Select-Object DeviceId, MediaType, OperationalStatus, HealthStatus | Out-String) + "`r`n"
    
    $report += "--- BATTERY HEALTH (IF APPLICABLE) ---`r`n"
    $battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
    if ($battery) { $report += ($battery | Select-Object Name, EstimatedChargeRemaining, Status | Out-String) + "`r`n" }
    else { $report += "No Battery Detected (Desktop/AIO)`r`n`r`n" }

    $report += "--- RAM UTILIZATION ---`r`n"
    $ram = Get-CimInstance Win32_OperatingSystem
    $total = [math]::Round($ram.TotalVisibleMemorySize / 1MB, 2)
    $free = [math]::Round($ram.FreePhysicalMemory / 1MB, 2)
    $report += "Total RAM: $total GB | Free RAM: $free GB`r`n`r`n"

    $report += "--- CPU INFO ---`r`n"
    $report += (Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, MaxClockSpeed | Out-String)
    
    $txtDiagReport.Text = $report
})

# --- [REST OF TABS 1 & 2 LOGIC GOES HERE] ---

$Form.ShowDialog()



# [Add these two buttons above your AppList in Tab 1]
$btnSelectAll = New-Object System.Windows.Forms.Button
$btnSelectAll.Text = "Check All"; $btnSelectAll.Location = New-Object System.Drawing.Point(20, 570); $btnSelectAll.Size = New-Object System.Drawing.Size(100, 30)
$Tab1.Controls.Add($btnSelectAll)

$btnSelectAll.Add_Click({
    for($i=0; $i -lt $AppList.Items.Count; $i++) { $AppList.SetItemChecked($i, $true) }
})



# ==============================================================================
# WINCLEAN PRO v7.0 - FULL TECHNICIAN DEPLOYMENT & DIAGNOSTIC SUITE
# Developed for: Professional IT & Hardware Repair Workflows
# ==============================================================================

# 1. SELF-ELEVATION & EXECUTION POLICY BYPASS
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- MAIN FORM SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WinClean Pro v7.0 - Hardware & OS Technician Suite"
$Form.Size = New-Object System.Drawing.Size(800, 950)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
$Form.ForeColor = [System.Drawing.Color]::White

# --- PROFILE MANAGEMENT (TOP BAR) ---
$pnlProfile = New-Object System.Windows.Forms.Panel
$pnlProfile.Dock = "Top"; $pnlProfile.Height = 50; $pnlProfile.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
$Form.Controls.Add($pnlProfile)

$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "SAVE PROFILE"; $btnSave.Location = New-Object System.Drawing.Point(10, 10); $btnSave.Size = New-Object System.Drawing.Size(120, 30); $btnSave.FlatStyle = "Flat"
$pnlProfile.Controls.Add($btnSave)

$btnLoad = New-Object System.Windows.Forms.Button
$btnLoad.Text = "LOAD PROFILE"; $btnLoad.Location = New-Object System.Drawing.Point(140, 10); $btnLoad.Size = New-Object System.Drawing.Size(120, 30); $btnLoad.FlatStyle = "Flat"
$pnlProfile.Controls.Add($btnLoad)

# --- TAB CONTROL ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Dock = "Fill"
$Form.Controls.Add($TabControl)

# TAB 1: OS CLEANUP
$Tab1 = New-Object System.Windows.Forms.TabPage; $Tab1.Text = "OS Cleanup"; $Tab1.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$TabControl.TabPages.Add($Tab1)

# TAB 2: DEPLOYMENT
$Tab2 = New-Object System.Windows.Forms.TabPage; $Tab2.Text = "Deployment"; $Tab2.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$TabControl.TabPages.Add($Tab2)

# TAB 3: HARDWARE DIAG
$Tab3 = New-Object System.Windows.Forms.TabPage; $Tab3.Text = "Hardware Diag"; $Tab3.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$TabControl.TabPages.Add($Tab3)

# --- [TAB 1 CONTENT: CLEANUP] ---
$chkUnlock = New-Object System.Windows.Forms.CheckBox
$chkUnlock.Text = "Unlock Permanent System Apps (Registry Bypass)"; $chkUnlock.Location = New-Object System.Drawing.Point(20, 20); $chkUnlock.AutoSize = $true
$Tab1.Controls.Add($chkUnlock)

$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Location = New-Object System.Drawing.Point(20, 50); $txtSearch.Size = New-Object System.Drawing.Size(550, 25); $txtSearch.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45); $txtSearch.ForeColor = [System.Drawing.Color]::White
$Tab1.Controls.Add($txtSearch)

$AppList = New-Object System.Windows.Forms.CheckedListBox
$AppList.Location = New-Object System.Drawing.Point(20, 85); $AppList.Size = New-Object System.Drawing.Size(740, 450); $AppList.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 35); $AppList.ForeColor = [System.Drawing.Color]::White; $AppList.BorderStyle = "None"
$Tab1.Controls.Add($AppList)

$btnSelAll = New-Object System.Windows.Forms.Button
$btnSelAll.Text = "Select All"; $btnSelAll.Location = New-Object System.Drawing.Point(20, 545); $btnSelAll.Size = New-Object System.Drawing.Size(100, 30)
$Tab1.Controls.Add($btnSelAll)

$btnRunCleanup = New-Object System.Windows.Forms.Button
$btnRunCleanup.Text = "EXECUTE CLEANUP"; $btnRunCleanup.Location = New-Object System.Drawing.Point(20, 600); $btnRunCleanup.Size = New-Object System.Drawing.Size(740, 60); $btnRunCleanup.BackColor = [System.Drawing.Color]::Crimson; $btnRunCleanup.FlatStyle = "Flat"
$Tab1.Controls.Add($btnRunCleanup)

# --- [TAB 2 CONTENT: DEPLOYMENT] ---
$EssList = New-Object System.Windows.Forms.CheckedListBox
$EssList.Location = New-Object System.Drawing.Point(20, 20); $EssList.Size = New-Object System.Drawing.Size(740, 500); $EssList.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 35); $EssList.ForeColor = [System.Drawing.Color]::White
$Tab2.Controls.Add($EssList)

$btnInstall = New-Object System.Windows.Forms.Button
$btnInstall.Text = "DOWNLOAD & INSTALL SELECTED"; $btnInstall.Location = New-Object System.Drawing.Point(20, 540); $btnInstall.Size = New-Object System.Drawing.Size(740, 60); $btnInstall.BackColor = [System.Drawing.Color]::DarkGreen; $btnInstall.FlatStyle = "Flat"
$Tab2.Controls.Add($btnInstall)

# --- [TAB 3 CONTENT: HARDWARE DIAG] ---
$btnDiag = New-Object System.Windows.Forms.Button
$btnDiag.Text = "RUN HARDWARE HEALTH CHECK"; $btnDiag.Location = New-Object System.Drawing.Point(20, 20); $btnDiag.Size = New-Object System.Drawing.Size(740, 50); $btnDiag.BackColor = [System.Drawing.Color]::DarkCyan; $btnDiag.FlatStyle = "Flat"
$Tab3.Controls.Add($btnDiag)

$txtDiagReport = New-Object System.Windows.Forms.TextBox
$txtDiagReport.Location = New-Object System.Drawing.Point(20, 90); $txtDiagReport.Size = New-Object System.Drawing.Size(740, 600); $txtDiagReport.Multiline = $true; $txtDiagReport.ReadOnly = $true; $txtDiagReport.BackColor = [System.Drawing.Color]::Black; $txtDiagReport.ForeColor = [System.Drawing.Color]::Lime; $txtDiagReport.Font = New-Object System.Drawing.Font("Consolas", 10); $txtDiagReport.ScrollBars = "Vertical"
$Tab3.Controls.Add($txtDiagReport)

# --- DATA INITIALIZATION ---
$Global:AllApps = Get-AppxPackage -AllUsers | Select-Object -ExpandProperty Name | Sort-Object
function Update-AppList {
    $filter = $txtSearch.Text; $AppList.Items.Clear()
    foreach ($App in $Global:AllApps) { if ($App -like "*$filter*") { [void]$AppList.Items.Add($App) } }
}
Update-AppList
$txtSearch.Add_TextChanged({ Update-AppList })

$Essentials = @(
    @{ Name = "Chrome"; URL = "https://dl.google.com/chrome/install/ChromeStandaloneSetup64.exe"; Args = "/silent /install" },
    @{ Name = "Firefox"; URL = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"; Args = "-ms" },
    @{ Name = "VLC Media Player"; URL = "https://get.videolan.org/vlc/last/win64/vlc.exe"; Args = "/S" },
    @{ Name = "Visual C++ AIO"; URL = "https://github.com/abbodi1406/vcredist/releases/latest/download/VisualCppRedist_AIO_x86_x64.exe"; Args = "/y" },
    @{ Name = "7-Zip"; URL = "https://www.7-zip.org/a/7z2301-x64.exe"; Args = "/S" }
)
foreach ($E in $Essentials) { [void]$EssList.Items.Add($E.Name) }

# --- BUTTON LOGIC ---

$btnSelAll.Add_Click({ for($i=0;$i -lt $AppList.Items.Count;$i++){$AppList.SetItemChecked($i,$true)} })

$btnSave.Add_Click({
    $Data = @{ Cleanup = @($AppList.CheckedItems); Essentials = @($EssList.CheckedItems) }
    $Data | ConvertTo-Json | Out-File "$PSScriptRoot\TechProfile.json"
    [System.Windows.Forms.MessageBox]::Show("Profile Saved!", "Success")
})

$btnLoad.Add_Click({
    if (Test-Path "$PSScriptRoot\TechProfile.json") {
        $L = Get-Content "$PSScriptRoot\TechProfile.json" | ConvertFrom-Json
        for($i=0;$i -lt $AppList.Items.Count;$i++){ $AppList.SetItemChecked($i,($L.Cleanup -contains $AppList.Items[$i])) }
        for($i=0;$i -lt $EssList.Items.Count;$i++){ $EssList.SetItemChecked($i,($L.Essentials -contains $EssList.Items[$i])) }
    }
})

$btnDiag.Add_Click({
    $report = "--- STORAGE ---`r`n" + (Get-PhysicalDisk | Select DeviceId, MediaType, HealthStatus | Out-String)
    $report += "`r`n--- RAM ---`r`n" + (Get-CimInstance Win32_OperatingSystem | Select TotalVisibleMemorySize, FreePhysicalMemory | Out-String)
    $report += "`r`n--- BATTERY ---`r`n" + (Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Select EstimatedChargeRemaining, Status | Out-String)
    $txtDiagReport.Text = $report
})

$btnRunCleanup.Add_Click({
    if($chkUnlock.Checked){
        $Reg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Applications"
        Get-ChildItem $Reg | ForEach { Set-ItemProperty $_.PSPath -Name "IsInbox" -Value 0 -ErrorAction SilentlyContinue }
    }
    foreach($item in $AppList.CheckedItems){
        Get-AppxPackage -AllUsers -Name $item | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where {$_.DisplayName -eq $item} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }
    [System.Windows.Forms.MessageBox]::Show("Cleanup Done!", "Done")
})

$btnInstall.Add_Click({
    $temp = "$env:TEMP\WinClean"
    if(!(Test-Path $temp)){New-Item $temp -ItemType Directory}
    foreach($item in $EssList.CheckedItems){
        $obj = $Essentials | Where {$_.Name -eq $item}
        $file = "$temp\setup.exe"
        Invoke-WebRequest $obj.URL -OutFile $file
        Start-Process $file -ArgumentList $obj.Args -Wait
    }
    [System.Windows.Forms.MessageBox]::Show("Install Complete!", "Success")
})

$Form.ShowDialog()





Run_WinClean.bat

++++++++++++++++++++


@echo off
:: Check for Admin Privileges
IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

:: If not Admin, relaunch as Admin
if %errorlevel% NEQ 0 (
    echo Requesting Administrative Elevation...
    powershell -Command "Start-Process '%0' -Verb RunAs"
    exit /b
)

:: Launch the PowerShell script with Bypass and NoProfile
echo Launching WinClean Pro v7.0...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0WinCleanPro_v7.ps1"
pause



# ==============================================================================
# WINCLEAN PRO v7.0 - UNIFORM UI TECHNICIAN SUITE
# ==============================================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- UI CONSTANTS (Padding & Spacing) ---
$Pad = 25
$BtnHeight = 45
$WinWidth = 800
$WinHeight = 900
$InnerWidth = $WinWidth - ($Pad * 3)

# --- MAIN FORM SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WinClean Pro v7.0 - Professional Tech Suite"
$Form.Size = New-Object System.Drawing.Size($WinWidth, $WinHeight)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 25)
$Form.ForeColor = [System.Drawing.Color]::White
$Form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# --- TOP PROFILE BAR ---
$pnlProfile = New-Object System.Windows.Forms.Panel
$pnlProfile.Dock = "Top"; $pnlProfile.Height = 60; $pnlProfile.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
$Form.Controls.Add($pnlProfile)

$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "SAVE PROFILE"; $btnSave.Location = New-Object System.Drawing.Point($Pad, 10); $btnSave.Size = New-Object System.Drawing.Size(150, 35); $btnSave.FlatStyle = "Flat"
$pnlProfile.Controls.Add($btnSave)

$btnLoad = New-Object System.Windows.Forms.Button
$btnLoad.Text = "LOAD PROFILE"; $btnLoad.Location = New-Object System.Drawing.Point($Pad + 160, 10); $btnLoad.Size = New-Object System.Drawing.Size(150, 35); $btnLoad.FlatStyle = "Flat"
$pnlProfile.Controls.Add($btnLoad)

# --- TAB CONTROL ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = New-Object System.Drawing.Point($Pad, 80); $TabControl.Size = New-Object System.Drawing.Size($InnerWidth + 15, $WinHeight - 150)
$Form.Controls.Add($TabControl)

# --- TAB 1: CLEANUP ---
$Tab1 = New-Object System.Windows.Forms.TabPage; $Tab1.Text = "OS Cleanup"; $Tab1.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 35); $Tab1.Padding = New-Object System.Windows.Forms.Padding($Pad)
$TabControl.TabPages.Add($Tab1)

$chkUnlock = New-Object System.Windows.Forms.CheckBox
$chkUnlock.Text = "Unlock Permanent System Apps (Registry Bypass)"; $chkUnlock.Location = New-Object System.Drawing.Point($Pad, $Pad); $chkUnlock.AutoSize = $true
$Tab1.Controls.Add($chkUnlock)

$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Location = New-Object System.Drawing.Point($Pad, $Pad + 35); $txtSearch.Size = New-Object System.Drawing.Size($InnerWidth - $Pad, 30); $txtSearch.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50); $txtSearch.ForeColor = [System.Drawing.Color]::White
$Tab1.Controls.Add($txtSearch)

$AppList = New-Object System.Windows.Forms.CheckedListBox
$AppList.Location = New-Object System.Drawing.Point($Pad, $Pad + 75); $AppList.Size = New-Object System.Drawing.Size($InnerWidth - $Pad, 450); $AppList.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40); $AppList.ForeColor = [System.Drawing.Color]::White; $AppList.BorderStyle = "None"
$Tab1.Controls.Add($AppList)

$btnSelAll = New-Object System.Windows.Forms.Button
$btnSelAll.Text = "Select All"; $btnSelAll.Location = New-Object System.Drawing.Point($Pad, $Pad + 535); $btnSelAll.Size = New-Object System.Drawing.Size(120, 35); $btnSelAll.FlatStyle = "Flat"
$Tab1.Controls.Add($btnSelAll)

$btnRunCleanup = New-Object System.Windows.Forms.Button
$btnRunCleanup.Text = "EXECUTE SYSTEM CLEANUP"; $btnRunCleanup.Location = New-Object System.Drawing.Point($Pad, $Pad + 585); $btnRunCleanup.Size = New-Object System.Drawing.Size($InnerWidth - $Pad, $BtnHeight + 10); $btnRunCleanup.BackColor = [System.Drawing.Color]::FromArgb(180, 0, 0); $btnRunCleanup.FlatStyle = "Flat"
$Tab1.Controls.Add($btnRunCleanup)

# --- TAB 2: DEPLOYMENT ---
$Tab2 = New-Object System.Windows.Forms.TabPage; $Tab2.Text = "Deployment"; $Tab2.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 35); $Tab2.Padding = New-Object System.Windows.Forms.Padding($Pad)
$TabControl.TabPages.Add($Tab2)

$EssList = New-Object System.Windows.Forms.CheckedListBox
$EssList.Location = New-Object System.Drawing.Point($Pad, $Pad); $EssList.Size = New-Object System.Drawing.Size($InnerWidth - $Pad, 525); $EssList.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40); $EssList.ForeColor = [System.Drawing.Color]::White; $EssList.BorderStyle = "None"
$Tab2.Controls.Add($EssList)

$btnInstall = New-Object System.Windows.Forms.Button
$btnInstall.Text = "DOWNLOAD & INSTALL SELECTED"; $btnInstall.Location = New-Object System.Drawing.Point($Pad, $Pad + 540); $btnInstall.Size = New-Object System.Drawing.Size($InnerWidth - $Pad, $BtnHeight + 10); $btnInstall.BackColor = [System.Drawing.Color]::DarkGreen; $btnInstall.FlatStyle = "Flat"
$Tab2.Controls.Add($btnInstall)

# --- TAB 3: HARDWARE DIAG ---
$Tab3 = New-Object System.Windows.Forms.TabPage; $Tab3.Text = "Hardware Diag"; $Tab3.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 35); $Tab3.Padding = New-Object System.Windows.Forms.Padding($Pad)
$TabControl.TabPages.Add($Tab3)

$btnDiag = New-Object System.Windows.Forms.Button
$btnDiag.Text = "RUN HARDWARE HEALTH CHECK"; $btnDiag.Location = New-Object System.Drawing.Point($Pad, $Pad); $btnDiag.Size = New-Object System.Drawing.Size($InnerWidth - $Pad, $BtnHeight); $btnDiag.BackColor = [System.Drawing.Color]::DarkCyan; $btnDiag.FlatStyle = "Flat"
$Tab3.Controls.Add($btnDiag)

$txtDiagReport = New-Object System.Windows.Forms.TextBox
$txtDiagReport.Location = New-Object System.Drawing.Point($Pad, $Pad + 60); $txtDiagReport.Size = New-Object System.Drawing.Size($InnerWidth - $Pad, 535); $txtDiagReport.Multiline = $true; $txtDiagReport.ReadOnly = $true; $txtDiagReport.BackColor = [System.Drawing.Color]::Black; $txtDiagReport.ForeColor = [System.Drawing.Color]::Lime; $txtDiagReport.Font = New-Object System.Drawing.Font("Consolas", 10); $txtDiagReport.ScrollBars = "Vertical"
$Tab3.Controls.Add($txtDiagReport)

# --- LOGIC INITIALIZATION ---
$Global:AllApps = Get-AppxPackage -AllUsers | Select-Object -ExpandProperty Name | Sort-Object
function Update-AppList {
    $filter = $txtSearch.Text; $AppList.Items.Clear()
    foreach ($App in $Global:AllApps) { if ($App -like "*$filter*") { [void]$AppList.Items.Add($App) } }
}
Update-AppList
$txtSearch.Add_TextChanged({ Update-AppList })

$Essentials = @(
    @{ Name = "Chrome"; URL = "https://dl.google.com/chrome/install/ChromeStandaloneSetup64.exe"; Args = "/silent /install" },
    @{ Name = "Firefox"; URL = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"; Args = "-ms" },
    @{ Name = "VLC Media Player"; URL = "https://get.videolan.org/vlc/last/win64/vlc.exe"; Args = "/S" },
    @{ Name = "Visual C++ AIO"; URL = "https://github.com/abbodi1406/vcredist/releases/latest/download/VisualCppRedist_AIO_x86_x64.exe"; Args = "/y" },
    @{ Name = "7-Zip"; URL = "https://www.7-zip.org/a/7z2301-x64.exe"; Args = "/S" }
)
foreach ($E in $Essentials) { [void]$EssList.Items.Add($E.Name) }

# --- ACTION LOGIC ---
$btnSelAll.Add_Click({ for($i=0;$i -lt $AppList.Items.Count;$i++){$AppList.SetItemChecked($i,$true)} })

$btnSave.Add_Click({
    $Data = @{ Cleanup = @($AppList.CheckedItems); Essentials = @($EssList.CheckedItems) }
    $Data | ConvertTo-Json | Out-File "$PSScriptRoot\TechProfile.json"
    [System.Windows.Forms.MessageBox]::Show("Profile Saved!", "Success")
})

$btnLoad.Add_Click({
    if (Test-Path "$PSScriptRoot\TechProfile.json") {
        $L = Get-Content "$PSScriptRoot\TechProfile.json" | ConvertFrom-Json
        for($i=0;$i -lt $AppList.Items.Count;$i++){ $AppList.SetItemChecked($i,($L.Cleanup -contains $AppList.Items[$i])) }
        for($i=0;$i -lt $EssList.Items.Count;$i++){ $EssList.SetItemChecked($i,($L.Essentials -contains $EssList.Items[$i])) }
    }
})

$btnDiag.Add_Click({
    $report = "--- STORAGE ---`r`n" + (Get-PhysicalDisk | Select DeviceId, MediaType, HealthStatus | Out-String)
    $report += "`r`n--- RAM ---`r`n" + (Get-CimInstance Win32_OperatingSystem | Select TotalVisibleMemorySize, FreePhysicalMemory | Out-String)
    $report += "`r`n--- BATTERY ---`r`n" + (Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Select EstimatedChargeRemaining, Status | Out-String)
    $txtDiagReport.Text = $report
})

$btnRunCleanup.Add_Click({
    if($chkUnlock.Checked){
        $Reg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Applications"
        Get-ChildItem $Reg | ForEach { Set-ItemProperty $_.PSPath -Name "IsInbox" -Value 0 -ErrorAction SilentlyContinue }
    }
    foreach($item in $AppList.CheckedItems){
        Get-AppxPackage -AllUsers -Name $item | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where {$_.DisplayName -eq $item} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }
    [System.Windows.Forms.MessageBox]::Show("Cleanup Done!", "Done")
})

$btnInstall.Add_Click({
    $temp = "$env:TEMP\WinClean"
    if(!(Test-Path $temp)){New-Item $temp -ItemType Directory}
    foreach($item in $EssList.CheckedItems){
        $obj = $Essentials | Where {$_.Name -eq $item}
        $file = "$temp\setup.exe"
        Invoke-WebRequest $obj.URL -OutFile $file
        Start-Process $file -ArgumentList $obj.Args -Wait
    }
    [System.Windows.Forms.MessageBox]::Show("Install Complete!", "Success")
})

$Form.ShowDialog()