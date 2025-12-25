# sink-switch for Windows

A powerful command-line and hotkey-driven utility to quickly switch between your audio playback devices on Windows.

This script allows you to create a curated list of your favorite audio devices and cycle through them with a simple command or a global hotkey, complete with toast notifications.

## Features

- **Device Management:**
  - **List:** See all available audio devices with their readable names and command-line IDs.
  - **Initialize:** Automatically generates a configuration file.
- **User-Controlled Cycling:**
  - **Enable/Disable:** Manually edit a configuration file to choose which devices are included in your cycle list.
  - **Predictable Cycle:** Switch in a simple, predictable round-robin order (A -> B -> C -> A).
- **Direct Access:** Instantly switch to any audio device by its ID.
- **Visual Feedback:** Displays a native Windows toast notification (with icon) on every successful switch when run from CLI. For hotkey use, an AutoHotkey `TrayTip` provides feedback.
- **Global Hotkeys:** Comes with an optional AutoHotkey script to bind cycling and setting commands to any key combination.
- **Robust:** Handles errors gracefully and is compatible with environments like Git Bash.

## Dependencies

1.  **PowerShell:** Included with all modern versions of Windows.
2.  **[SoundVolumeView.exe](https://www.nirsoft.net/utils/sound_volume_view.html):** A free command-line utility from NirSoft. It must be placed in the `tools` sub-directory.
3.  **[AutoHotkey](https://www.autohotkey.com/) (Optional):** Required only if you want to use global hotkeys.
4.  **`BurntToast` PowerShell Module:** Required for toast notifications (CLI use).

## Installation & Setup

1.  **Install Notification Module:** Open PowerShell **as Administrator** and run the following command:
    ```powershell
    Install-Module -Name BurntToast
    ```

2.  **File Structure:** Create a `tools` folder in the same directory as the script. Place `SoundVolumeView.exe` inside it. You can also place a `speaker.ico` file for the notification icon.
    ```
    sink-switch/
    ├── sink-switch.ps1
    ├── keybindings.ahk
    ├── README.md
    └── tools/
        ├── SoundVolumeView.exe
        └── speaker.ico
    ```

3.  **Initialize Configuration:** Open a PowerShell terminal in the project directory and run the `init` command. This creates the main configuration file in `%APPDATA%\sink-switch\config.json`.
    ```powershell
    .\sink-switch.ps1 init
    ```

4.  **Enable Your Devices:** Open the configuration file. By default, only your main devices are enabled. To include other devices in your cycle list, change their `"enabled"` property from `false` to `true`.
    ```powershell
    notepad "$env:APPDATA\sink-switch\config.json"
    ```

## Usage (Command Line)

All commands can be run from a PowerShell terminal.

- **`list` (alias: `ls`)**: Lists all available audio devices and their IDs.
- **`cycle` (alias: `cy`)**: Switches to the next device in your enabled list.
- **`set <DeviceID>` (alias: `s`)**: Sets a specific audio device as the default.
- **`current` (alias: `c`)**: Shows the current default playback and recording devices.

## Usage (Global Hotkeys)

To use global hotkeys from anywhere in Windows, ensure `keybindings.ahk` is running.

1.  **Run the script:** Double-click `keybindings.ahk`. A green "H" icon appears in your system tray.
2.  **Use the default hotkey:** Press `Alt + Mute` (`!Volume_Mute::`) to cycle devices.
3.  **Feedback:** A simple `TrayTip` notification will appear from the system tray, indicating the device change.
4.  **Customize (Optional):** Edit `keybindings.ahk` to change hotkeys or add specific `set` commands.

## Future Development

The current PowerShell script is stable and feature-complete. A future version may be rewritten in Go to provide a single, dependency-free executable and interact directly with native Windows APIs like WASAPI for potentially faster performance.
