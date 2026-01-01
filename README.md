# Sink Switch

<p align="center">
  <img src="logo.svg" width="200" alt="Sink Switch Logo">
</p>

**Sink Switch** is a cross-platform utility to instantly toggle your default audio playback device with a global hotkey.

It is designed to be **smart**, lightweight, and extremely fast.

---

## 🪟 Windows Version

The Windows version is a native Go application that talks directly to Windows Core Audio APIs.

### Features
- **⚡ Instant Switching:** Native performance, no lag.
- **🖥️ Dashboard UI:** Select which devices to cycle through via a clean GUI.
- **🧠 Smart Memory:** Remembers your last active hardware device, allowing for perfect cycling even when using virtual audio mixers like **FxSound**, **Voicemeeter**, or **SteelSeries Sonar**.
- **⌨️ Hotkey Support:** Includes an AutoHotkey script for `Alt + Mute` switching.

### Installation
1.  Download `sink-switch.exe` from the [Releases](https://github.com/KanishkMishra143/sink-switch-windows/releases) page.
2.  Run it once to configure your devices.
3.  Use the included `keybindings.ahk` (in the source) or create your own to run `sink-switch.exe -cycle`.

---

## 🐧 Linux Version

The Linux version is a lightweight Bash script that wraps `pactl` (PulseAudio/PipeWire).

### Features
- **🚀 Zero Dependencies:** Works on any distro with PulseAudio or PipeWire (`pactl` installed).
- **🔔 Notifications:** Uses `notify-send` to show the active device name and icon on switch.
- **🔄 Smart Filtering:** Automatically ignores "HDMI" or "Monitor" audio outputs if you only care about speakers/headphones.

### Installation
1.  Copy `linux/sink-switch.sh` to your local bin (e.g., `~/.local/bin/`).
2.  Make it executable: `chmod +x sink-switch.sh`.
3.  Bind it to a custom shortcut in your Desktop Environment settings (e.g., `Super + A`).

---

## 🏗️ Development

### Windows (Go)
```bash
cd windows
go get github.com/lxn/walk
go build -ldflags "-H windowsgui" -o sink-switch.exe
```

### Linux (Bash)
No build required. Just run the script.

---

## 📄 License
MIT License. Free to use and modify.