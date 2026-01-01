package main

import (
	"log"
	"strings"

	"github.com/lxn/walk"
	. "github.com/lxn/walk/declarative"
)

// RunDashboard launches the GUI
func RunDashboard() {
	var mainWindow *walk.MainWindow
	var deviceListBox *walk.TableView
	var model *DeviceModel

	// Load initial data
	allDevices, err := getAudioDevices()
	if err != nil {
		walk.MsgBox(nil, "Error", "Failed to load audio devices: "+err.Error(), walk.MsgBoxIconError)
		return
	}

	config, err := loadConfig()
	if err != nil {
		config = &Config{}
	}
	currentID, _ := getDefaultDeviceID()

	// Prepare Model
	model = NewDeviceModel(allDevices, config.Devices, currentID)

	// Define Layout
	if _, err := (MainWindow{
		AssignTo: &mainWindow,
		Title:    "Sink Switch Dashboard",
		MinSize:  Size{Width: 400, Height: 500},
		Layout:   VBox{},
		Children: []Widget{
			Label{
				Text: "Select devices to include in the toggle cycle:",
			},
			TableView{
				AssignTo:         &deviceListBox,
				AlternatingRowBG: true,
				CheckBoxes:       true,
				Columns: []TableViewColumn{
					{Title: "Device Name", Width: 280},
					{Title: "Status", Width: 80},
				},
				Model: model,
				OnItemActivated: func() {
					// Double click to switch immediately
					idx := deviceListBox.CurrentIndex()
					if idx >= 0 && idx < len(model.items) {
						target := model.items[idx].Device
						if err := setDefaultDevice(target.ID); err != nil {
							walk.MsgBox(mainWindow, "Error", "Failed to switch: "+err.Error(), walk.MsgBoxIconError)
						} else {
							// Update Status column
							currentID, _ = getDefaultDeviceID()
							model.UpdateCurrent(currentID)
						}
					}
				},
			},
			Composite{
				Layout: HBox{},
				Children: []Widget{
					PushButton{
						Text: "Switch to Selected",
						OnClicked: func() {
							idx := deviceListBox.CurrentIndex()
							if idx >= 0 && idx < len(model.items) {
								target := model.items[idx].Device
								if err := setDefaultDevice(target.ID); err != nil {
									walk.MsgBox(mainWindow, "Error", "Failed to switch: "+err.Error(), walk.MsgBoxIconError)
								} else {
									currentID, _ = getDefaultDeviceID()
									model.UpdateCurrent(currentID)
								}
							}
						},
					},
					HSpacer{},
					PushButton{
						Text: "Save Config",
						OnClicked: func() {
							// Gather checked items
							var newCycleList []string
							for _, item := range model.items {
								if item.Checked {
									newCycleList = append(newCycleList, item.Device.Name)
								}
							}
							
							config.Devices = newCycleList

							// Update LastDeviceID if the current actual device is in our new list
							// This helps the CLI cycle start from the correct relative position
							currentRealID, _ := getDefaultDeviceID()
							for _, item := range model.items {
								if item.Device.ID == currentRealID && item.Checked {
									config.LastDeviceID = currentRealID
									break
								}
							}

							if err := saveConfig(config); err != nil {
								walk.MsgBox(mainWindow, "Error", "Failed to save config: "+err.Error(), walk.MsgBoxIconError)
							} else {
								walk.MsgBox(mainWindow, "Success", "Configuration saved successfully!", walk.MsgBoxIconInformation)
							}
						},
					},
				},
			},
			Label{
				Text: "Double-click a device to switch immediately.",
				TextColor: walk.RGB(100, 100, 100),
			},
		},
	}).Run(); err != nil {
		log.Fatal(err)
	}
}

// --- Table Model Helper ---

type DeviceItem struct {
	Device  AudioDevice
	Checked bool
	Status  string // "Active" or ""
}

type DeviceModel struct {
	walk.TableModelBase
	items []*DeviceItem
}

func NewDeviceModel(devices []AudioDevice, cycleNames []string, currentID string) *DeviceModel {
	m := &DeviceModel{items: make([]*DeviceItem, len(devices))}
	
	// Helper to check if name is in cycle list
	inCycle := func(name string) bool {
		for _, c := range cycleNames {
			// Looser matching for config compatibility
			if strings.Contains(strings.ToLower(name), strings.ToLower(c)) {
				return true
			}
		}
		return false
	}

	for i, d := range devices {
		status := ""
		if d.ID == currentID {
			status = "Active"
		}
		
		m.items[i] = &DeviceItem{
			Device:  d,
			Checked: inCycle(d.Name),
			Status:  status,
		}
	}
	return m
}

func (m *DeviceModel) RowCount() int {
	return len(m.items)
}

func (m *DeviceModel) Value(row, col int) interface{} {
	item := m.items[row]
	switch col {
	case 0:
		return item.Device.Name
	case 1:
		return item.Status
	}
	return ""
}

func (m *DeviceModel) Checked(row int) bool {
	return m.items[row].Checked
}

func (m *DeviceModel) SetChecked(row int, checked bool) error {
	m.items[row].Checked = checked
	return nil
}

func (m *DeviceModel) UpdateCurrent(newID string) {
	for _, item := range m.items {
		if item.Device.ID == newID {
			item.Status = "Active"
		} else {
			item.Status = ""
		}
	}
	m.PublishRowsReset()
}
