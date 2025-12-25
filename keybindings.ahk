#NoEnv
#Warn
SendMode Input
SetWorkingDir, %A_ScriptDir%

; --- HOTKEY DEFINITIONS ---

!Volume_Mute::
    ; Define a path for a temporary output file
    tempFile := A_Temp . "\sink-switch-output.txt"
    
    ; Construct a command to run the PS script hidden and redirect its output to the temp file
    command := "cmd /c powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ . A_ScriptDir . "\sink-switch.ps1"" cycle > """ . tempFile . """"
    
    ; Run the command completely hidden
    Run, %command%, , Hide
    
    ; Wait a brief moment for the script to run and write the file
    Sleep, 400
    
    ; Read the device name from the temp file
    FileRead, result, %tempFile%
    
    ; Display the result in a TrayTip and then delete the temporary file
    TrayTip, Audio Switcher, %result%, 1
    FileDelete, %tempFile%
return