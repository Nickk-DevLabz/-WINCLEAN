📘 WinClean Pro: Technician’s ReadMe

Purpose: To standardize the "Post-Repair" or "New PC" setup process by removing bloatware, locking drivers, and installing essentials in one automated pass.
📂 Tab 1: OS Cleanup & Debloat

    The "Unlock" Checkbox: Use this only on stubborn systems. It modifies the Registry to make "Permanent" apps removable.

    Search/Filter: Type names like Xbox, Weather, or YourPhone to quickly find and check them for removal.

    The "Deep Clean" Logic: This doesn't just uninstall the app; it takes ownership of C:\Program Files\WindowsApps to delete the physical files and reclaim GBs of storage.

🚀 Tab 2: Deployment (Essentials)

    Post-Cleanup Setup: Since Phase 1 might remove Edge, use this tab to install a new browser (Chrome/Firefox) and critical runtimes (Visual C++, DirectX).

    Silent Mode: All installers are programmed to run in the background. Do not manually open any installers while the script is running.

🔍 Tab 3: Hardware Diagnostics

    Pre-Cleanup Check: Always run this first. If a MacBook or PC has a "Failing" S.M.A.R.T status on the SSD, do not proceed with the cleanup. Backup the data and replace the drive first.

    Battery Check: Useful for verifying if a client needs a battery replacement during a routine service.

🔧 Next Steps & Maintenance Guide

To keep this tool professional and functional over the long term, follow these three maintenance rules:

1. Update the "Essentials" URLs

Software vendors (Google, Mozilla, VideoLAN) occasionally change their direct-download links.

    Frequency: Every 6 months.

    Action: If a download fails, find the new "Standalone/Offline Installer" URL for that app and paste it into the $Essentials array in the script.

2. The "Profile" Strategy

Create a folder on your technician USB named Profiles. Save different JSON configurations for different client needs:

    Gaming.json: Aggressive removal, Update Pause enabled, All Runtimes installed.

    Business.json: Keep Calculator/Store, Update Pause disabled, Office/Chrome installed.

3. Execution Policy Reset

Since you'll be running this on many different machines, remember the "Sandwich" command sequence:

    Open Admin PowerShell.

    Unlock: Set-ExecutionPolicy Bypass -Scope Process -Force

    Run: .\WinCleanPro_v7.ps1

    Lock (Optional): Set-ExecutionPolicy Restricted -Scope LocalMachine
