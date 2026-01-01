# Sink Switch

<p align="center">
  <img src="logo.svg" width="200" alt="Sink Switch Logo">
</p>

**Sink Switch** is a cross-platform utility designed to instantly toggle your default audio playback device with a global hotkey. It prioritizes performance, reliability, and ease of use.

---

## Windows Version

The Windows version is a native Go application that interacts directly with Windows Core Audio APIs for low-latency switching.

### Features

- **Instant Switching:** Direct API calls ensure zero lag when toggling devices.
- **Dashboard UI:** A clean interface to select exactly which devices you want to include in the cycle loop.
- **Smart Memory:** Intelligently handles virtual audio mixers (like FxSound, Voicemeeter, or SteelSeries Sonar) by remembering the last active hardware device associated with them.
- **Global Hotkey Support:** Designed to work seamlessly with automation tools like AutoHotkey.

### Installation & Usage

1.  **Download:** Get the latest `sink-switch.exe` from the [Releases](https://github.com/KanishkMishra143/sink-switch-windows/releases) page.
2.  **Configuration:** Run `sink-switch.exe` (double-click) to open the dashboard. Select the audio devices you wish to cycle through and close the window. A `config.json` file will be created.

### Setting up Hotkeys (Windows)

To switch devices with a keyboard shortcut, you need to execute `sink-switch.exe` with the `-cycle` flag. The recommended method is using **AutoHotkey**.

1.  **Install AutoHotkey:** Download and install it from [autohotkey.com](https://www.autohotkey.com/).
2.  **Create Script:**
    *   Create a new text file named `keybindings.ahk` in the same folder as `sink-switch.exe`.
    *   Paste the following code into the file:
        ```autohotkey
        #NoEnv
        SendMode Input
        SetWorkingDir, %A_ScriptDir%

        ; Alt + Mute to cycle audio devices
        !Volume_Mute::
            Run, "sink-switch.exe" -cycle, %A_ScriptDir%, Hide
        return
        ```
3.  **Run:** Double-click `keybindings.ahk` to activate the shortcut. Press `Alt + Mute` (or your defined key) to test.
4.  **Auto-Start:** To have this run automatically on boot:
    *   Press `Win + R`, type `shell:startup`, and press Enter.
    *   Create a shortcut to your `keybindings.ahk` file and place it in this folder.

---

## Linux Version

The Linux version is a robust Bash script wrapper for `pactl` (PulseAudio/PipeWire), offering a dependency-free experience on most modern distributions.

### Features

- **Zero Dependencies:** Relies only on standard system tools (`pactl`, `notify-send`) commonly found in distributions using PulseAudio or PipeWire.
- **Desktop Notifications:** Displays a system notification with the name of the new active device upon switching.
- **Smart Filtering:** Can be configured to ignore specific output types (like HDMI) to keep your cycle list clean.

### Installation

1.  **Download:** Save the `sink-switch.sh` script to a directory in your path (e.g., `~/.local/bin/`).
    ```bash
    mkdir -p ~/.local/bin
    cp linux/sink-switch.sh ~/.local/bin/sink-switch
    ```
2.  **Permissions:** Make the script executable.
    ```bash
    chmod +x ~/.local/bin/sink-switch
    ```

### Setting up Hotkeys (Linux)

You can bind the script to a global keyboard shortcut using your desktop environment's settings.

#### GNOME
1.  Open **Settings** > **Keyboard** > **View and Customize Shortcuts**.
2.  Scroll down to **Custom Shortcuts**.
3.  Click **Add Shortcut**.
    *   **Name:** Sink Switch
    *   **Command:** `sink-switch` (or `/full/path/to/sink-switch` if not in PATH)
    *   **Shortcut:** Set your desired key combination (e.g., `Super + A`).

#### KDE Plasma
1.  Open **System Settings** > **Shortcuts** > **Custom Shortcuts**.
2.  Right-click in the list > **New** > **Global Shortcut** > **Command/URL**.
3.  Name it "Sink Switch".
4.  **Trigger:** Set your key combination.
5.  **Action:** Enter `sink-switch` (or `/full/path/to/sink-switch`).

---

## Development

### Windows (Go)

Prerequisites: Go 1.25+

```powershell
cd windows/go-version
go mod download
go build -ldflags "-H windowsgui" -o sink-switch.exe
```

### Linux (Bash)

No build process is required. The script can be run directly from the source.

```bash
cd linux
./sink-switch.sh --help
```

---

## License

MIT License. Free to use and modify.
