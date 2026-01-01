#NoEnv
#Warn
SendMode Input
SetWorkingDir, %A_ScriptDir%

; --- HOTKEY DEFINITIONS ---

!Volume_Mute::
    ; Directly run the PowerShell script. 
    ; 'Run' handles the environment better than piping via cmd /c.
    ; We hide the console window so it doesn't pop up.
    Run, powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%A_ScriptDir%\sink-switch.ps1" cycle, %A_ScriptDir%, Hide
return