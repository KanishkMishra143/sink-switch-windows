# Sink Switch

<p align="center">
  <img src="logo.svg" width="200" alt="Sink Switch Logo">
</p>

**Sink Switch** is a lightweight, high-performance Windows utility that allows you to toggle your default audio playback device (Speakers, Headphones, TV, etc.) instantly with a global hotkey.

Unlike other tools, Sink Switch is **smart**: it remembers your last toggle state, making it perfect for complex setups involving audio enhancers like **FxSound**, where the active device might not always reflect the target hardware.

---

## 🚀 Features

- **⚡ Instant Switching:** Written in Go for native performance. Directly talks to Windows Core Audio APIs (COM).
- **🖥️ Dashboard UI:** Includes a native Windows GUI to easily select which devices you want to cycle through.
- **🧠 Smart Memory:** Remembers exactly which device was last active, ensuring 100% reliable cycling even if virtual audio drivers (like FxSound or Voicemeeter) mask the real hardware.
- **⌨️ Global Hotkey:** Comes with an AutoHotkey script to bind `Alt + Mute` (or any key you like) to the switcher.
- **🪶 Lightweight:** Single binary, minimal resource usage.

---

## 📥 Installation

1.  **Download:** Go to the [Releases](https://github.com/YOUR_USERNAME/sink-switch/releases) page and download `sink-switch.exe`.
2.  **Place it:** Move the `.exe` to a permanent location (e.g., `D:\My Apps\sink-switch\`).
3.  **Hotkey Setup:**
    *   Install [AutoHotkey](https://www.autohotkey.com/) (v1.1 or v2).
    *   Download the `keybindings.ahk` file (or create one, see below).
    *   Double-click `keybindings.ahk` to run it. (Right-click -> "Compile" to make it a standalone executable if you prefer).

---

## ⚙️ Configuration

### 1. The Dashboard
Double-click `sink-switch.exe` to open the **Dashboard**.

*   **Check** the boxes next to the devices you want to include in your toggle cycle (e.g., "Speakers (Realtek)" and "USB Audio").
*   **Double-click** any device name to switch to it immediately.
*   Click **"Save Config"** to save your preferences to `config.json`.

### 2. The Hotkey (CLI Mode)
The switcher has a hidden "CLI Mode" optimized for speed.
Command: `sink-switch.exe -cycle`

This reads your config, finds the next device in the loop, and switches to it instantly.

**Example `keybindings.ahk`:**
```autohotkey
; Alt + Mute to Toggle Audio Devices
!Volume_Mute::
    Run, "path\to\sink-switch.exe" -cycle, path\to, Hide
return
```

---

## 🛠️ How it Works (Under the Hood)

Windows Audio APIs are complex. Most switchers just check "What is the current default?" and switch to the next one.
**The problem:** If you use **FxSound**, the "Current Default" is *always* FxSound. A normal switcher gets stuck in a loop, trying to switch away from FxSound and failing to track state.

**The Sink Switch Solution:**
We store a `last_device_id` in `config.json`.
1.  When you press the hotkey, we read `config.json`.
2.  We see you were last on "Speakers A".
3.  We ignore what Windows *says* is active (which might be FxSound) and confidently switch the hardware to "Speakers B".
4.  We update the config: `last_device_id = Speakers B`.

This ensures perfect cycling every time.

---

## 🏗️ Building from Source

Requirements: **Go 1.20+**

```bash
# Clone the repo
git clone https://github.com/your-repo/sink-switch.git
cd sink-switch/go-version

# Install dependencies
go get github.com/lxn/walk
go get github.com/go-ole/go-ole
go get github.com/moutend/go-wca

# Build (Hides console window for GUI)
go build -ldflags "-H windowsgui" -o sink-switch.exe
```

---

## 📄 License

MIT License. Free to use and modify.