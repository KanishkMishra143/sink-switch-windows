# sink-switch.ps1

# Define the path to SoundVolumeView.exe
# PSScriptRoot is the directory where the script is located.
$SoundVolumeViewPath = Join-Path $PSScriptRoot "tools\SoundVolumeView.exe"

# --- Pre-flight Check ---
# Check if SoundVolumeView.exe exists
if (-not (Test-Path $SoundVolumeViewPath -PathType Leaf)) {
    Write-Host "Error: SoundVolumeView.exe not found at '$SoundVolumeViewPath'."
    Write-Host "Please ensure that SoundVolumeView.exe is located in the 'tools' directory relative to the script."
    exit 1
}

# --- Global Variables ---
$configDir = Join-Path $env:APPDATA "sink-switch"
$configFile = Join-Path $configDir "config.json"

# Function to list audio devices
function List-AudioDevices {
    Write-Host "--- Listing Audio Output Devices ---"

    $tempCsvPath = Join-Path $env:TEMP "devices.csv"
    # /ShowDevices 2 filters for Playback devices
    $arguments = "/scomma `"$tempCsvPath`" /ShowDevices 2"

    Start-Process -FilePath $SoundVolumeViewPath -ArgumentList $arguments -Wait -NoNewWindow

    if (Test-Path $tempCsvPath -PathType Leaf) {
        # Import the CSV. Filter for only 'Device' types that are not disabled or unplugged.
        $devices = Import-Csv -Path $tempCsvPath | Where-Object {
            $_.Type -eq 'Device' -and
            $_.State -ne 'Disabled' -and
            $_.State -ne 'Unplugged'
        }

        Write-Host "The following endpoint devices were found:"
        Write-Host ""
        # Display a clean, formatted list with Name and the unique ID
        $devices | ForEach-Object {
            Write-Host "  Name: $($_.Name)"
            Write-Host "  Device Name: $($_.('Device Name'))"
            Write-Host "    ID: $($_.'Command-Line Friendly ID')"
            Write-Host ""
        }

        Remove-Item -Path $tempCsvPath
    }
    else {
        Write-Host "Error: Could not generate the device list from SoundVolumeView.exe."
    }
}

function Init-Configuration {
    Write-Host "--- Initializing Configuration ---"

    if (-not (Test-Path $configDir -PathType Container)) {
        New-Item -Path $configDir -ItemType Directory | Out-Null
    }

    if (-not (Test-Path $SoundVolumeViewPath -PathType Leaf)) {
        Write-Host "Error: SoundVolumeView.exe not found at '$SoundVolumeViewPath'."
        Write-Host "Please ensure that SoundVolumeView.exe is located in the 'tools' directory relative to the script."
        return
    }

    $tempCsvPath = Join-Path $env:TEMP "devices.csv"
    $arguments = "/scomma `"$tempCsvPath`""

    Start-Process -FilePath $SoundVolumeViewPath -ArgumentList $arguments -Wait -NoNewWindow

    if (Test-Path $tempCsvPath -PathType Leaf) {
        $devices = Import-Csv -Path $tempCsvPath | Where-Object {
            $_.Type -eq 'Device' -and
            $_.State -ne 'Disabled' -and
            $_.State -ne 'Unplugged'
        }

        if ($devices) {
            $configDevices = @()
            foreach ($device in $devices) {
                $isDefault = $false
                if ($device.Default -eq 'Render' -or $device.Default -eq 'Capture') {
                    $isDefault = $true
                }
                $configDevice = [PSCustomObject]@{
                    name        = $device.Name
                    device_name = $device.'Device Name'
                    id          = $device.'Command-Line Friendly ID'
                    enabled     = if ($isDefault) { $true } else { $false }
                }
                $configDevices += $configDevice
            }

            $finalConfigObject = @{
                lastCycledId = ""
                devices      = $configDevices
            }

            $jsonConfig = $finalConfigObject | ConvertTo-Json -Depth 5
            $jsonConfig | Out-File -FilePath $configFile -Encoding UTF8

            Write-Host "Configuration file created at '$configFile'."
        }
        else {
            Write-Host "No active audio endpoint devices found."
        }
        Remove-Item -Path $tempCsvPath
    }
    else {
        Write-Host "Error: Could not generate the device list from SoundVolumeView.exe."
    }
}

# function Cycle-AudioDevices {
#     Write-Host "--- Cycling Audio Devices ---"

#     if (-not (Test-Path $configFile -PathType Leaf)) {
#         Write-Host "Configuration file not found. Please run 'sink-switch.ps1 init' first."
#         return
#     }

#     $configContent = Get-Content -Path $configFile
#     if (-not $configContent) {
#         Write-Host "Configuration file is empty. Please run 'sink-switch.ps1 init' first."
#         return
#     }
#     try {
#         $config = $configContent | ConvertFrom-Json
#     } catch {
#         Write-Host "Invalid configuration file. Please run 'sink-switch.ps1 init' first."
#         return
#     }

#     $enabledDevices = $config | Where-Object { $_.enabled -eq $true }

#     if (-not $enabledDevices) {
#         Write-Host "No enabled devices found in configuration. Please enable devices in config.json."
#         return
#     }

#     # Get the current default device directly from SoundVolumeView
#     $tempCsvPath = Join-Path $env:TEMP "current_devices.csv"
#     Start-Process -FilePath $SoundVolumeViewPath -ArgumentList "/scomma `"$tempCsvPath`"" -Wait -NoNewWindow
#     $allDevices = Import-Csv -Path $tempCsvPath
#     $currentDefault = $allDevices | Where-Object { $_.Default -eq 'Render' }
#     Remove-Item -Path $tempCsvPath

#     $currentIndex = -1
#     if ($currentDefault) {
#         $currentIndex = [array]::IndexOf($enabledDevices.id, $currentDefault.'Command-Line Friendly ID')
#     }

#     # Determine the next index, wrapping around if needed
#     $nextIndex = ($currentIndex + 1) % $enabledDevices.Count
#     $nextDevice = $enabledDevices[$nextIndex]

#     # Switch to the next device
#     $arguments = "/SetDefault `"`"$($nextDevice.id)`"`" all"
#     Start-Process -FilePath $SoundVolumeViewPath -ArgumentList $arguments -Wait -NoNewWindow

#     # Add a short delay to allow the system to register the change
#     Start-Sleep -Seconds 1

#     Write-Host "Switched to: $($nextDevice.name) ($($nextDevice.device_name))"
# }
# function Cycle-AudioDevices {
#     Write-Host "--- Cycling Audio Devices ---"

#     if (-not (Test-Path $configFile -PathType Leaf)) {
#         Write-Host "Configuration file not found. Please run 'sink-switch.ps1 init' first."
#         return
#     }

#     $configContent = Get-Content -Path $configFile
#     if (-not $configContent) {
#         Write-Host "Configuration file is empty. Please run 'sink-switch.ps1 init' first."
#         return
#     }
#     try {
#         $config = $configContent | ConvertFrom-Json
#     } catch {
#         Write-Host "Invalid configuration file. Please run 'sink-switch.ps1 init' first."
#         return
#     }

#     # Validate that config object has 'devices' array and 'lastCycledId' property
#     if (-not $config.PSObject.Properties.Contains('devices') -or -not ($config.devices -is [array])) {
#         Write-Host "Configuration file format incorrect. Missing 'devices' array. Please run 'sink-switch.ps1 init' first."
#         return
#     }
#     if (-not $config.PSObject.Properties.Contains('lastCycledId')) {
#         Write-Host "Configuration file format incorrect. Missing 'lastCycledId' property. Please run 'sink-switch.ps1 init' first."
#     return
    
#     $enabledDevices = $config.devices | Where-Object { $_.enabled -eq $true }

#     if (-not $enabledDevices) {
#         Write-Host "No enabled devices found in configuration. Please enable devices in config.json."
#         return
#     }

#     $lastId = $config.lastCycledId
#     $lastIndex = [array]::IndexOf($enabledDevices.id, $lastId)
    
#     # Determine the next index, wrapping around if needed
#     # If lastId was not found in enabledDevices (e.g., it was disabled or it's the first run)
#     # start from the beginning of the enabled list
#     if ($lastIndex -eq -1) {
#         $nextIndex = 0
#     } else {
#         $nextIndex = ($lastIndex + 1) % $enabledDevices.Count
#     }
#     $nextDevice = $enabledDevices[$nextIndex]

#     # Switch to the next device
#     $arguments = "/SetDefault `"`"$($nextDevice.id)`"`" all"
#     Start-Process -FilePath $SoundVolumeViewPath -ArgumentList $arguments -Wait -NoNewWindow

#     # Update the lastCycledId in the config object
#     $config.lastCycledId = $nextDevice.id

#     # Save the entire updated configuration object back to the file
#     $config | ConvertTo-Json -Depth 5 | Out-File -FilePath $configFile -Encoding UTF8

#     Write-Host "Switched to: $($nextDevice.name) ($($nextDevice.device_name))"
#     }
# }
function Cycle-AudioDevices {
    Write-Host "--- Cycling Audio Devices ---"
    if (-not (Test-Path $configFile -PathType Leaf)) {
        Write-Host "Configuration file not found. Please run 'sink-switch.ps1 init' first."
        return
    }
    $configContent = Get-Content -Path $configFile
    if (-not $configContent) {
        Write-Host "Configuration file is empty. Please run 'sink-switch.ps1 init' first."
        return
    }
    try {
        $config = $configContent | ConvertFrom-Json
    }
    catch {
        Write-Host "Invalid configuration file. Please run 'sink-switch.ps1 init' first."
        return
    }
    # Validate that config object has 'devices' array and 'lastCycledId' property
    if (-not ($config.psobject.properties.Name -contains 'devices') -or -not ($config.devices -is [array])) {
        Write-Host "Configuration file format incorrect. Missing 'devices' array. Please run 'sink-switch.ps1 init' first."
        return
    }
    if (-not ($config.psobject.properties.Name -contains 'lastCycledId')) {
        Write-Host "Configuration file format incorrect. Missing 'lastCycledId' property. Please run 'sink-switch.ps1 init' first."
        return
    }
    $enabledDevices = $config.devices | Where-Object { $_.enabled -eq $true }
    if (-not $enabledDevices) {
        Write-Host "No enabled devices found in configuration. Please enable devices in config.json."
        return
    }
    $lastId = $config.lastCycledId
    $lastIndex = [array]::IndexOf($enabledDevices.id, $lastId)
    # Determine the next index, wrapping around if needed
    if ($lastIndex -eq -1) {
        $nextIndex = 0
    }
    else {
        $nextIndex = ($lastIndex + 1) % $enabledDevices.Count
    }
    $nextDevice = $enabledDevices[$nextIndex]
    # Switch to the next device
    $arguments = "/SetDefault `"`"$($nextDevice.id)`"`" all"
    Start-Process -FilePath $SoundVolumeViewPath -ArgumentList $arguments -Wait -NoNewWindow
    # Update the lastCycledId in the config object
    $config.lastCycledId = $nextDevice.id
    # Save the entire updated configuration object back to the file
    $config | ConvertTo-Json -Depth 5 | Out-File -FilePath $configFile -Encoding UTF8
    Show-Notification -DeviceName $nextDevice.name -SubName $nextDevice.device_name
    "Switched to: $($nextDevice.name) ($($nextDevice.device_name))"
}
function Set-AudioDevice {
    param(
        [string]$DeviceID
    )

    Write-Host "--- Setting Audio Device ---"

    # NORMALIZE THE INPUT: Replace double backslashes with a single backslash for comparison
    $normalizedDeviceID = $DeviceID.Replace('\\', '\')

    if (-not (Test-Path $configFile -PathType Leaf)) {
        Write-Host "Configuration file not found. Please run 'sink-switch.ps1 init' first."
        return
    }

    $configContent = Get-Content -Path $configFile
    if (-not $configContent) {
        Write-Host "Configuration file is empty. Please run 'sink-switch.ps1 init' first."
        return
    }
    try {
        $config = $configContent | ConvertFrom-Json
    }
    catch {
        Write-Host "Invalid configuration file. Please run 'sink-switch.ps1 init' first."
        return
    }
    $selectedDevice = $config.devices | Where-Object { $_.id -eq $normalizedDeviceID }

    if ($selectedDevice) {
        # Escape single quotes in the DeviceID for the command line argument (for SoundVolumeView.exe)
        $escapedDeviceID = $selectedDevice.id.Replace("'", "''")
        # Switch to the selected device
        $arguments = "/SetDefault `"`"$escapedDeviceID`"`" all"
        Start-Process -FilePath $SoundVolumeViewPath -ArgumentList $arguments -Wait -NoNewWindow

        # Save the updated configuration
        $config | ConvertTo-Json -Depth 5 | Out-File -FilePath $configFile -Encoding UTF8
        Show-Notification -DeviceName $nextDevice.name -SubName $nextDevice.device_name
        "Switched to: $($selectedDevice.name) ($($selectedDevice.device_name))"
    }
    else {
        Write-Host "Error: Device with ID '$DeviceID' not found in the configuration."
    }
}

function Get-CurrentDevice {
    Write-Host "--- Current Audio Device ---"

    $tempCsvPath = Join-Path $env:TEMP "devices.csv"
    $arguments = "/scomma `"$tempCsvPath`""

    Start-Process -FilePath $SoundVolumeViewPath -ArgumentList $arguments -Wait -NoNewWindow

    if (Test-Path $tempCsvPath -PathType Leaf) {
        $devices = Import-Csv -Path $tempCsvPath | Where-Object {
            $_.Type -eq 'Device' -and
            $_.State -ne 'Disabled' -and
            $_.State -ne 'Unplugged'
        }

        if ($devices) {
            $defaultPlayback = $devices | Where-Object { $_.Default -eq 'Render' }
            $defaultCapture = $devices | Where-Object { $_.Default -eq 'Capture' }

            if ($defaultPlayback) {
                Write-Host "Default Playback Device:"
                Write-Host "  Name: $($defaultPlayback.Name)"
                Write-Host "  Device Name: $($defaultPlayback.'Device Name')"
                Write-Host ""
            }
            else {
                Write-Host "No default playback device found."
            }

            if ($defaultCapture) {
                Write-Host "Default Capture Device:"
                Write-Host "  Name: $($defaultCapture.Name)"
                Write-Host "  Device Name: $($defaultCapture.'Device Name')"
            }
            else {
                Write-Host "No default capture device found."
            }
        }
        else {
            Write-Host "No active audio endpoint devices found."
        }

        Remove-Item -Path $tempCsvPath
    }
    else {
        Write-Host "Error: Could not generate the device list from SoundVolumeView.exe."
    }
}
function Show-Notification {
    param(
        [string]$DeviceName,
        [string]$SubName
    )
    # This creates a toast notification using the BurntToast module.
    New-BurntToastNotification -AppLogo (Join-Path $PSScriptRoot "tools\speaker.png") -Text "Switched to: $DeviceName", $SubName -UniqueIdentifier "sink-switch-device"
}

# --- Main Script Logic ---
if ($args.Count -ge 1) {
    $command = $args[0].ToLower()

    switch ($command) {
        "list" {
            List-AudioDevices
        }
        "ls" {
            List-AudioDevices
        }
        "init" {
            Init-Configuration
        }
        "cycle" {
            Cycle-AudioDevices
        }
        "cy" {
            Cycle-AudioDevices
        }
        "set" {
            if ($args.Count -ge 2) {
                Set-AudioDevice -DeviceID $args[1]
            }
            else {
                Write-Host "Please provide the ID of the device to set."
            }
        }
        "s" {
            if ($args.Count -ge 2) {
                Set-AudioDevice -DeviceID $args[1]
            }
            else {
                Write-Host "Please provide the ID of the device to set."
            }
        }
        "current" {
            Get-CurrentDevice
        }
        "c" {
            Get-CurrentDevice
        }
        # Other commands will be added here later
        default {
            Write-Host "Unknown command: $command"
            Write-Host "Usage: sink-switch.ps1 [list(ls) | init | cycle(cy) | set(s) <value> | current(c)]"
        }
    }
}
else {
    Write-Host "No command provided."
    Write-Host "Usage: sink-switch.ps1 [list(ls) | init | cycle(cy) | set(s) <value> | current(c)]"
}