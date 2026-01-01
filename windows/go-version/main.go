package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"syscall"
	"unsafe"

	"github.com/go-ole/go-ole"
	"github.com/moutend/go-wca/pkg/wca"
)

// --- Configuration ---

type Config struct {
	Devices      []string `json:"devices"`        // List of friendly names or IDs to cycle through
	LastDeviceID string   `json:"last_device_id"` // Persistent state
}

const (
	AppName     = "SinkSwitch"
	ConfigFile  = "config.json"
	VTableIndex = 12 // Confirmed working index for this system
)

var (
	// IPolicyConfigVista
	CLSID_PolicyConfig = ole.NewGUID("294935CE-F637-4E7C-A41B-AB255460B862")
	IID_IPolicyConfig  = ole.NewGUID("568b9108-44bf-40b4-9006-86afe5b5a620")
)

// AudioDevice struct
type AudioDevice struct {
	ID   string
	Name string
}

func main() {
	// 1. Parse Flags
	cycleMode := flag.Bool("cycle", false, "Cycle through configured devices (CLI mode)")
	listMode := flag.Bool("list", false, "List all available audio devices and exit")
	flag.Parse()

	// 2. Console Management
	// If no CLI flags are set, we assume GUI mode.
	// Since we are building as a Console app (to fix CLI glitching), we must manually hide the console window.
	if !*cycleMode && !*listMode {
		hideConsole()
	}

	// Ensure COM is ready for whatever happens next
	if err := ole.CoInitializeEx(0, ole.COINIT_APARTMENTTHREADED); err != nil {
		log.Fatal(err)
	}
	defer ole.CoUninitialize()

	if *listMode {
		runList()
		return
	}

	if *cycleMode {
		runCycle()
	} else {
		// Launch GUI
		RunDashboard()
	}
}

func hideConsole() {
	kernel32 := syscall.NewLazyDLL("kernel32.dll")
	user32 := syscall.NewLazyDLL("user32.dll")

	getConsoleWindow := kernel32.NewProc("GetConsoleWindow")
	showWindow := user32.NewProc("ShowWindow")

	hwnd, _, _ := getConsoleWindow.Call()
	if hwnd != 0 {
		// SW_HIDE = 0
		showWindow.Call(hwnd, 0)
	}
}

func runList() {
	devices, err := getAudioDevices()
	if err != nil {
		log.Fatal(err)
	}
	currentID, _ := getDefaultDeviceID()
	printDevices(devices, currentID)
}

func runCycle() {
	// 1. Get all active devices
	allDevices, err := getAudioDevices()
	if err != nil {
		log.Fatal(err)
	}

	// 2. Load Config
	config, err := loadConfig()
	if err != nil {
		config = &Config{}
	}

	// 3. Determine the "Cycle List"
	var cycleList []AudioDevice
	// Support explicit args even in cycle mode: sink-switch.exe -cycle "Device A" "Device B"
	// Flag parsing eats the flags, remaining args are in flag.Args()
	if len(flag.Args()) > 0 {
		cycleList = filterDevices(allDevices, flag.Args())
		if len(cycleList) < 2 {
			log.Fatalf("Error: Arguments matched fewer than 2 devices.")
		}
	} else if len(config.Devices) > 0 {
		cycleList = filterDevices(allDevices, config.Devices)
		if len(cycleList) < 2 {
			// fallback silently or warn? Warn is better for CLI.
			// fmt.Println("Warning: Config matches < 2 devices. Falling back to all.")
			cycleList = allDevices
		}
	} else {
		cycleList = allDevices
	}

	if len(cycleList) < 2 {
		log.Fatal("Not enough devices to switch between.")
	}

	// 4. Determine current position
	currentIndex := -1
	if config.LastDeviceID != "" {
		for i, d := range cycleList {
			if d.ID == config.LastDeviceID {
				currentIndex = i
				break
			}
		}
	}

	if currentIndex == -1 {
		realCurrentID, _ := getDefaultDeviceID()
		for i, d := range cycleList {
			if d.ID == realCurrentID {
				currentIndex = i
				break
			}
		}
	}

	// 5. Calculate Next Target
	var target AudioDevice
	if currentIndex == -1 {
		target = cycleList[0]
		fmt.Printf("Starting cycle at: %s\n", target.Name)
	} else {
		nextIndex := (currentIndex + 1) % len(cycleList)
		target = cycleList[nextIndex]
		fmt.Printf("Cycling [%s] -> [%s]\n", cycleList[currentIndex].Name, target.Name)
	}

	// 6. Execute Switch
	if err := setDefaultDevice(target.ID); err != nil {
		log.Fatalf("Failed to switch: %v", err)
	}

	// 7. Save State
	config.LastDeviceID = target.ID
	saveConfig(config)
	fmt.Println("Success.")
}

// --- Helper Logic (Shared) ---

func loadConfig() (*Config, error) {
	path, err := getConfigPath()
	if err != nil {
		return nil, err
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var cfg Config
	if err := json.Unmarshal(data, &cfg); err != nil {
		return nil, err
	}
	return &cfg, nil
}

func saveConfig(cfg *Config) error {
	path, err := getConfigPath()
	if err != nil {
		return err
	}
	data, err := json.MarshalIndent(cfg, "", "    ")
	if err != nil {
		return err
	}
	return os.WriteFile(path, data, 0644)
}

func getConfigPath() (string, error) {
	// Standard Location: %APPDATA%\SinkSwitch\config.json
	configDir, err := os.UserConfigDir()
	if err != nil {
		// Fallback to local directory if we can't get user config dir
		return ConfigFile, nil
	}

	appDir := filepath.Join(configDir, AppName)
	if err := os.MkdirAll(appDir, 0755); err != nil {
		return ConfigFile, nil
	}

	return filepath.Join(appDir, ConfigFile), nil
}

func filterDevices(all []AudioDevice, patterns []string) []AudioDevice {
	var matches []AudioDevice
	seen := make(map[string]bool)
	for _, pattern := range patterns {
		lowerPat := strings.ToLower(pattern)
		for _, d := range all {
			if seen[d.ID] {
				continue
			}
			if d.ID == pattern || strings.Contains(strings.ToLower(d.Name), lowerPat) {
				matches = append(matches, d)
				seen[d.ID] = true
			}
		}
	}
	return matches
}

func getNames(devices []AudioDevice) []string {
	names := make([]string, len(devices))
	for i, d := range devices {
		names[i] = d.Name
	}
	return names
}

func printDevices(devices []AudioDevice, currentID string) {
	fmt.Println("--- Audio Devices ---")
	for _, d := range devices {
		prefix := "   "
		if d.ID == currentID {
			prefix = " * "
		}
		fmt.Printf("%s%s\n", prefix, d.Name)
		fmt.Printf("      ID: %s\n", d.ID)
	}
}

// --- Native COM Wrappers ---

type IPolicyConfig struct {
	ole.IUnknown
}

func setDefaultDevice(deviceID string) error {
	ole.CoInitializeEx(0, ole.COINIT_APARTMENTTHREADED)
	defer ole.CoUninitialize()

	var pc *IPolicyConfig
	err := wca.CoCreateInstance(CLSID_PolicyConfig, 0, wca.CLSCTX_ALL, IID_IPolicyConfig, &pc)
	if err != nil {
		return fmt.Errorf("failed to create PolicyConfig: %w", err)
	}
	defer pc.Release()

	idPtr, err := syscall.UTF16PtrFromString(deviceID)
	if err != nil {
		return err
	}

	roles := []int{0, 1, 2}
	vtable := (*[20]uintptr)(unsafe.Pointer(pc.RawVTable))
	methodPtr := vtable[VTableIndex]

	for _, role := range roles {
		hr, _, _ := syscall.Syscall(
			methodPtr,
			3,
			uintptr(unsafe.Pointer(pc)),
			uintptr(unsafe.Pointer(idPtr)),
			uintptr(role),
		)
		if hr != 0 {
			return fmt.Errorf("SetDefaultEndpoint failed (HR: %x)", hr)
		}
	}
	return nil
}

func getDefaultDeviceID() (string, error) {
	ole.CoInitializeEx(0, ole.COINIT_APARTMENTTHREADED)
	defer ole.CoUninitialize()

	var de *wca.IMMDeviceEnumerator
	if err := wca.CoCreateInstance(wca.CLSID_MMDeviceEnumerator, 0, wca.CLSCTX_ALL, wca.IID_IMMDeviceEnumerator, &de); err != nil {
		return "", err
	}
	defer de.Release()

	var device *wca.IMMDevice
	if err := de.GetDefaultAudioEndpoint(wca.ERender, wca.EMultimedia, &device); err != nil {
		return "", err
	}
	defer device.Release()

	var idStr string
	if err := device.GetId(&idStr); err != nil {
		return "", err
	}
	return idStr, nil
}

func getAudioDevices() ([]AudioDevice, error) {
	ole.CoInitializeEx(0, ole.COINIT_APARTMENTTHREADED)
	defer ole.CoUninitialize()

	var de *wca.IMMDeviceEnumerator
	if err := wca.CoCreateInstance(wca.CLSID_MMDeviceEnumerator, 0, wca.CLSCTX_ALL, wca.IID_IMMDeviceEnumerator, &de); err != nil {
		return nil, err
	}
	defer de.Release()

	var dc *wca.IMMDeviceCollection
	if err := de.EnumAudioEndpoints(wca.ERender, wca.DEVICE_STATE_ACTIVE, &dc); err != nil {
		return nil, err
	}
	defer dc.Release()

	var count uint32
	if err := dc.GetCount(&count); err != nil {
		return nil, err
	}

	var devices []AudioDevice
	for i := uint32(0); i < count; i++ {
		var device *wca.IMMDevice
		if err := dc.Item(i, &device); err != nil {
			continue
		}

		var idStr string
		if err := device.GetId(&idStr); err != nil {
			device.Release()
			continue
		}

		var ps *wca.IPropertyStore
		if err := device.OpenPropertyStore(wca.STGM_READ, &ps); err != nil {
			device.Release()
			continue
		}

		var pv wca.PROPVARIANT
		key := wca.PROPERTYKEY{ole.GUID{Data1: 0xa45c254e, Data2: 0xdf1c, Data3: 0x4efd, Data4: [8]byte{0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0}}, 14}

		if err := ps.GetValue(&key, &pv); err == nil {
			devices = append(devices, AudioDevice{ID: idStr, Name: pv.String()})
		}
		ps.Release()
		device.Release()
	}
	return devices, nil
}
