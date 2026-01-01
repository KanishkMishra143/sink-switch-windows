#NoEnv
#Warn
SendMode Input
SetWorkingDir, %A_ScriptDir%

; --- Sink Switch Hotkey ---
; Alt + Volume_Mute toggles between configured audio devices
!Volume_Mute::
    Run, "%A_ScriptDir%\sink-switch.exe" -cycle, %A_ScriptDir%, Hide
return