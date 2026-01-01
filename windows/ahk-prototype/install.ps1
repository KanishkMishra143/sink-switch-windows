# install.ps1 - Setup script for sink-switch

# # --- 1. Admin Privilege Check ---
# if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRol"Administrator")) {
#     Write-Host "Requesting Administrator privileges to install dependencies..."
#     Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
#     exit
# }

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot
$ToolsDir = Join-Path $ScriptRoot "tools"

Write-Host "--- Sink-Switch Installer ---" -ForegroundColor Cyan

# --- 2. Install BurntToast Module ---
Write-Host "`n[1/4] Checking for BurntToast module..."
if (-not (Get-Module -ListAvailable -Name BurntToast)) {
    Write-Host "Installing BurntToast module..." -ForegroundColor Yellow
    try {
        # Install to CurrentUser scope to be safe and portable
        Install-Module -Name BurntToast -Scope CurrentUser -Force -AllowClobber
        Write-Host "BurntToast installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Error installing BurntToast: $_" -ForegroundColor Red
        Write-Host "You may need to manually run: Install-Module -Name BurntToast -Scope CurrentUser"
        # Continue anyway, as the script might work without notifications or user can fix later
    }
}
else {
    Write-Host "BurntToast is already installed." -ForegroundColor Green
}

# --- 3. Download & Setup SoundVolumeView ---
Write-Host "`n[2/4] Setting up SoundVolumeView..."
if (-not (Test-Path $ToolsDir)) {
    New-Item -Path $ToolsDir -ItemType Directory | Out-Null
    Write-Host "Created 'tools' directory."
}
$SoundVolumeViewPath = Join-Path $ToolsDir "SoundVolumeView.exe"
if (-not (Test-Path $SoundVolumeViewPath)) {
    Write-Host "Downloading SoundVolumeView (x64)..." -ForegroundColor Yellow
    $DownloadUrl = "https://www.nirsoft.net/utils/soundvolumeview-x64.zip"
    $ZipPath = Join-Path $env:TEMP "soundvolumeview.zip"
    try {
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath
        Write-Host "Extracting..."
        # Extract specific file
        Expand-Archive -Path $ZipPath -DestinationPath $env:TEMP -Force
        $ExtractedExe = Join-Path $env:TEMP "SoundVolumeView.exe"
        Move-Item -Path $ExtractedExe -Destination $SoundVolumeViewPath -Force
        Write-Host "SoundVolumeView installed to $ToolsDir" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to download or extract SoundVolumeView." -ForegroundColor Red
        Write-Host "Error: $_"
        Write-Host "Please manually download it from https://www.nirsoft.net/utils/soundvolumeview.html and place it in the 'tools' folder."     
    }
    finally {
        if (Test-Path $ZipPath) { Remove-Item $ZipPath -ErrorAction SilentlyContinue }
        # Cleanup potential temp extraction
        Remove-Item (Join-Path $env:TEMP "SoundVolumeView.exe") -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $env:TEMP "SoundVolumeView.chm") -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $env:TEMP "readme.txt") -ErrorAction SilentlyContinue
    }
}
else {
    Write-Host "SoundVolumeView.exe already exists." -ForegroundColor Green
}
# --- 4. Initialize Config ---
Write-Host "`n[3/4] Initializing Configuration..."
try {
    & "$ScriptRoot\sink-switch.ps1" init
}
catch {
    Write-Host "Failed to run initialization: $_" -ForegroundColor Red
}
# --- 5. Create Startup Shortcut ---
Write-Host "`n[4/4] Creating Startup Shortcut..."
try {
    $WshShell = New-Object -ComObject WScript.Shell
    $StartupFolder = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
    $ShortcutPath = Join-Path $StartupFolder "sink-switch-hotkeys.lnk"
    
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = Join-Path $ScriptRoot "keybindings.ahk"
    $Shortcut.WorkingDirectory = $ScriptRoot
    $Shortcut.Description = "Global hotkeys for sink-switch"
    $Shortcut.Save()
    
    Write-Host "Startup shortcut created at: $ShortcutPath" -ForegroundColor Green
}
catch {
    Write-Host "Failed to create startup shortcut: $_" -ForegroundColor Red
}

Write-Host "`nSetup Complete!" -ForegroundColor Cyan
Write-Host "------------------------------------------------"
Write-Host "You can now use 'Alt + Mute' to cycle audio devices."
Write-Host "------------------------------------------------"
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")