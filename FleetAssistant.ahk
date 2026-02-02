#Requires AutoHotkey v2.0
#SingleInstance Force

; ========================================================================================
; Global Variables
; ========================================================================================
global GuiObj := ""
global RavenKeyInput := ""
global FleetKeyInput := ""
global FleetRiskDropdown := ""
global Deck1Dropdown := ""
global Deck2Dropdown := ""
global Deck3Dropdown := ""
global Deck4Dropdown := ""
global RepairWaitInput := ""
global RecoverRestockTimerInput := ""
global RepairTimerInput := ""
global SettingBackTimerInput := ""

global RavenKey := "1"
global FleetKey := "y"
global FleetRisk := "Maximize Profit"
global Deck1Task := "Trading"
global Deck2Task := "Petrol/Plunder"
global Deck3Task := "Recover"
global Deck4Task := "Recover"
global RepairWaitTime := 1000
global RecoverRestockTimer := 1800
global RepairTimer := 240
global SettingBackTimer := 1200

global IsRunning := false
global ActionInProgress := false
global RecoverRestockTimerActive := true
global SettingBackTimerActive := false
global RecoverRestockTimerObj := ""
global RepairTimerObj := ""
global SettingBackTimerObj := ""
global PendingRepair := false

; ========================================================================================
; Load Settings on Startup
; ========================================================================================
LoadSettings()

; ========================================================================================
; Create GUI
; ========================================================================================
CreateGUI()

; ========================================================================================
; Hotkeys
; ========================================================================================
F1::StartScript()
F2::Reload
F3::ExitScript()

; ========================================================================================
; Functions - Settings Management
; ========================================================================================
LoadSettings() {
    settingFile := A_ScriptDir . "\Setting.txt"
    
    if !FileExist(settingFile)
        return
    
    try {
        content := FileRead(settingFile)
        lines := StrSplit(content, "`n", "`r")
        
        for line in lines {
            line := Trim(line)
            if (line = "" || !InStr(line, "="))
                continue
            
            parts := StrSplit(line, "=", , 2)
            key := Trim(parts[1])
            value := Trim(parts[2])
            
            switch key {
                case "RavenKey": global RavenKey := value
                case "FleetKey": global FleetKey := value
                case "FleetRisk": global FleetRisk := value
                case "Deck1Task": global Deck1Task := value
                case "Deck2Task": global Deck2Task := value
                case "Deck3Task": global Deck3Task := value
                case "Deck4Task": global Deck4Task := value
                case "RepairWaitTime": global RepairWaitTime := Integer(value)
                case "RecoverRestockTimer": global RecoverRestockTimer := Integer(value)
                case "RepairTimer": global RepairTimer := Integer(value)
                case "SettingBackTimer": global SettingBackTimer := Integer(value)
            }
        }
    }
}

SaveSettings(*) {
    settingFile := A_ScriptDir . "\Setting.txt"
    
    ; Get current values from GUI
    global RavenKey := RavenKeyInput.Value
    global FleetKey := FleetKeyInput.Value
    global FleetRisk := FleetRiskDropdown.Text
    global Deck1Task := Deck1Dropdown.Text
    global Deck2Task := Deck2Dropdown.Text
    global Deck3Task := Deck3Dropdown.Text
    global Deck4Task := Deck4Dropdown.Text
    global RepairWaitTime := Integer(RepairWaitInput.Value)
    global RecoverRestockTimer := Integer(RecoverRestockTimerInput.Value)
    global RepairTimer := Integer(RepairTimerInput.Value)
    global SettingBackTimer := Integer(SettingBackTimerInput.Value)
    
    content := ""
    content .= "RavenKey=" . RavenKey . "`n"
    content .= "FleetKey=" . FleetKey . "`n"
    content .= "FleetRisk=" . FleetRisk . "`n"
    content .= "Deck1Task=" . Deck1Task . "`n"
    content .= "Deck2Task=" . Deck2Task . "`n"
    content .= "Deck3Task=" . Deck3Task . "`n"
    content .= "Deck4Task=" . Deck4Task . "`n"
    content .= "RepairWaitTime=" . RepairWaitTime . "`n"
    content .= "RecoverRestockTimer=" . RecoverRestockTimer . "`n"
    content .= "RepairTimer=" . RepairTimer . "`n"
    content .= "SettingBackTimer=" . SettingBackTimer . "`n"
    
    try {
        FileDelete(settingFile)
    }
    FileAppend(content, settingFile)
    
    MsgBox("Settings saved successfully!", "Fleet Assistant", "0x40")
}

; ========================================================================================
; Functions - GUI Creation
; ========================================================================================
CreateGUI() {
    global GuiObj := Gui("-Caption +AlwaysOnTop +ToolWindow", "Fleet Assistant")
    GuiObj.BackColor := "0x2B2B2B"
    GuiObj.SetFont("s10 c0xFFFFFF", "Segoe UI")
    
    ; Make GUI moveable
    GuiObj.OnEvent("Close", (*) => ExitScript())
    
    ; Title Bar (for moving)
    titleBar := GuiObj.Add("Text", "x0 y0 w400 h30 Center BackgroundTrans", "⚓ Fleet Assistant")
    titleBar.SetFont("s12 Bold c0x4A9EFF")
    titleBar.OnEvent("Click", (*) => PostMessage(0xA1, 2))
    
    yPos := 40
    
    ; Hotkeys Section
    GuiObj.Add("Text", "x20 y" . yPos . " w360", "Hotkeys").SetFont("s9 c0x888888")
    yPos += 20
    
    GuiObj.Add("Text", "x20 y" . yPos . " w120", "RavenKey:")
    global RavenKeyInput := GuiObj.Add("Edit", "x140 y" . yPos . " w100", RavenKey)
    RavenKeyInput.SetFont("s9 c0x000000")
    yPos += 35
    
    GuiObj.Add("Text", "x20 y" . yPos . " w120", "FleetKey:")
    global FleetKeyInput := GuiObj.Add("Edit", "x140 y" . yPos . " w100", FleetKey)
    FleetKeyInput.SetFont("s9 c0x000000")
    yPos += 45
    
    ; Fleet Risk Section
    GuiObj.Add("Text", "x20 y" . yPos . " w360", "Fleet Risk").SetFont("s9 c0x888888")
    yPos += 20
    
    global FleetRiskDropdown := GuiObj.Add("DropDownList", "x20 y" . yPos . " w360", ["Maximize Profit", "Minimize Profit"])
    FleetRiskDropdown.SetFont("s9 c0x000000")
    FleetRiskDropdown.Text := FleetRisk
    yPos += 45
    
    ; Deck Tasks Section
    GuiObj.Add("Text", "x20 y" . yPos . " w360", "Deck Tasks").SetFont("s9 c0x888888")
    yPos += 20
    
    tasks := ["Exploring", "Recover", "Petrol/Plunder", "Fishing", "Harvesting", "Conquest", "Trading"]
    
    GuiObj.Add("Text", "x20 y" . yPos . " w120", "Deck 1:")
    global Deck1Dropdown := GuiObj.Add("DropDownList", "x140 y" . yPos . " w220", tasks)
    Deck1Dropdown.SetFont("s9 c0x000000")
    Deck1Dropdown.Text := Deck1Task
    yPos += 35
    
    GuiObj.Add("Text", "x20 y" . yPos . " w120", "Deck 2:")
    global Deck2Dropdown := GuiObj.Add("DropDownList", "x140 y" . yPos . " w220", tasks)
    Deck2Dropdown.SetFont("s9 c0x000000")
    Deck2Dropdown.Text := Deck2Task
    yPos += 35
    
    GuiObj.Add("Text", "x20 y" . yPos . " w120", "Deck 3:")
    global Deck3Dropdown := GuiObj.Add("DropDownList", "x140 y" . yPos . " w220", tasks)
    Deck3Dropdown.SetFont("s9 c0x000000")
    Deck3Dropdown.Text := Deck3Task
    yPos += 35
    
    GuiObj.Add("Text", "x20 y" . yPos . " w120", "Deck 4:")
    global Deck4Dropdown := GuiObj.Add("DropDownList", "x140 y" . yPos . " w220", tasks)
    Deck4Dropdown.SetFont("s9 c0x000000")
    Deck4Dropdown.Text := Deck4Task
    yPos += 45
    
    ; Repair Wait Time
    GuiObj.Add("Text", "x20 y" . yPos . " w360", "Repair Wait Time").SetFont("s9 c0x888888")
    yPos += 20
    
    GuiObj.Add("Text", "x20 y" . yPos . " w120", "Wait Time (ms):")
    global RepairWaitInput := GuiObj.Add("Edit", "x140 y" . yPos . " w100", RepairWaitTime)
    RepairWaitInput.SetFont("s9 c0x000000")
    GuiObj.Add("Text", "x2250 y" . (yPos + 2) . " w140", "1sec = 1000ms").SetFont("s8 c0x666666")
    yPos += 45
    
    ; Timer Settings
    GuiObj.Add("Text", "x20 y" . yPos . " w360", "Timer Settings").SetFont("s9 c0x888888")
    yPos += 20
    
    GuiObj.Add("Text", "x20 y" . yPos . " w120", "Recover & Restock:")
    global RecoverRestockTimerInput := GuiObj.Add("Edit", "x140 y" . yPos . " w100", RecoverRestockTimer)
    RecoverRestockTimerInput.SetFont("s9 c0x000000")
    GuiObj.Add("Text", "x2250 y" . (yPos + 2) . " w100", "seconds").SetFont("s8 c0x666666")
    yPos += 35
    
    GuiObj.Add("Text", "x20 y" . yPos . " w120", "Repair Timer:")
    global RepairTimerInput := GuiObj.Add("Edit", "x140 y" . yPos . " w100", RepairTimer)
    RepairTimerInput.SetFont("s9 c0x000000")
    GuiObj.Add("Text", "x2250 y" . (yPos + 2) . " w100", "seconds").SetFont("s8 c0x666666")
    yPos += 35
    
    GuiObj.Add("Text", "x20 y" . yPos . " w120", "Setting Back Task:")
    global SettingBackTimerInput := GuiObj.Add("Edit", "x140 y" . yPos . " w100", SettingBackTimer)
    SettingBackTimerInput.SetFont("s9 c0x000000")
    GuiObj.Add("Text", "x2250 y" . (yPos + 2) . " w100", "seconds").SetFont("s8 c0x666666")
    yPos += 45
    
    ; Save Button
    saveBtn := GuiObj.Add("Button", "x20 y" . yPos . " w360 h35", "💾 SAVE SETTINGS")
    saveBtn.SetFont("s10 Bold c0x000000")
    saveBtn.OnEvent("Click", SaveSettings)
    yPos += 45
    
    ; Control Instructions
    GuiObj.Add("Text", "x20 y" . yPos . " w360 Center", "F1: Start  |  F2: Reload  |  F3: Exit").SetFont("s8 c0x666666")
    yPos += 25
    
    GuiObj.Show("x0 y0 w400 h" . yPos)
}

; ========================================================================================
; Functions - Script Control
; ========================================================================================
StartScript() {
    global IsRunning, RecoverRestockTimerActive, SettingBackTimerActive
    
    if IsRunning
        return
    
    ; Update global variables from GUI
    global RavenKey := RavenKeyInput.Value
    global FleetKey := FleetKeyInput.Value
    global FleetRisk := FleetRiskDropdown.Text
    global Deck1Task := Deck1Dropdown.Text
    global Deck2Task := Deck2Dropdown.Text
    global Deck3Task := Deck3Dropdown.Text
    global Deck4Task := Deck4Dropdown.Text
    global RepairWaitTime := Integer(RepairWaitInput.Value)
    global RecoverRestockTimer := Integer(RecoverRestockTimerInput.Value)
    global RepairTimer := Integer(RepairTimerInput.Value)
    global SettingBackTimer := Integer(SettingBackTimerInput.Value)
    
    global IsRunning := true
    global ActionInProgress := true
    global RecoverRestockTimerActive := true
    global SettingBackTimerActive := false
    global PendingRepair := false
    
    ; Run startup phase
    RunStartupPhase()
}

ExitScript(*) {
    global IsRunning, ActionInProgress
    global RecoverRestockTimerObj, RepairTimerObj, SettingBackTimerObj
    
    IsRunning := false
    ActionInProgress := false
    
    ; Stop all timers
    if RecoverRestockTimerObj
        SetTimer(RecoverRestockTimerObj, 0)
    if RepairTimerObj
        SetTimer(RepairTimerObj, 0)
    if SettingBackTimerObj
        SetTimer(SettingBackTimerObj, 0)
    
    ExitApp()
}

; ========================================================================================
; Functions - Navigation
; ========================================================================================
ClickCenter() {
    Click()
    Sleep(1250)
}

NavigateToCommandTask() {
    Send("\")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("a")
    Sleep(250)
    Send("{Enter}")
    Sleep(250)
    Send("\")
}

NavigateToRestock() {
    Send("\")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("{Enter}")
    Sleep(250)
    Send("\")
}

NavigateToFleetRisk() {
    Send("\")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("d")
    Sleep(250)
    Send("{Enter}")
    Sleep(250)
    Send("\")
}

NavigateToDeck1() {
    Send("\")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("a")
    Sleep(250)
    Send("{Enter}")
    Sleep(250)
    Send("\")
}

NavigateToDeck2() {
    Send("\")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("{Enter}")
    Sleep(250)
    Send("\")
}

NavigateToDeck3() {
    Send("\")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("d")
    Sleep(250)
    Send("{Enter}")
    Sleep(250)
    Send("\")
}

NavigateToDeck4() {
    Send("\")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("d")
    Sleep(250)
    Send("d")
    Sleep(250)
    Send("{Enter}")
    Sleep(250)
    Send("\")
}

NavigateToTask(task) {
    Send("\")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("w")
    Sleep(250)
    
    switch task {
        case "Exploring":
            Send("w")
            Sleep(250)
            Send("w")
            Sleep(250)
            Send("w")
            Sleep(250)
        case "Recover":
            Send("w")
            Sleep(250)
            Send("w")
            Sleep(250)
        case "Petrol/Plunder":
            Send("w")
            Sleep(250)
        case "Fishing":
            ; Already at position
        case "Harvesting":
            Send("s")
            Sleep(250)
        case "Conquest":
            Send("s")
            Sleep(250)
            Send("s")
            Sleep(250)
        case "Trading":
            Send("s")
            Sleep(250)
            Send("s")
            Sleep(250)
            Send("s")
            Sleep(250)
    }
    
    Send("{Enter}")
    Sleep(250)
    Send("\")
}

NavigateToYes() {
    Send("\")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("{Enter}")
    Sleep(250)
    Send("\")
}

NavigateToMaximizeProfit() {
    Send("\")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("{Enter}")
    Sleep(250)
    Send("\")
}

NavigateToMinimizeProfit() {
    Send("\")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("{Enter}")
    Sleep(250)
    Send("\")
}

NavigateToRepairShip() {
    Send("\")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("s")
    Sleep(250)
    Send("d")
    Sleep(250)
    Send("d")
    Sleep(250)
    Send("s")
    Sleep(250)
    Send("{Enter}")
    Sleep(RepairWaitTime)
    Send("w")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("a")
    Sleep(250)
    Send("w")
    Sleep(250)
    Send("{Enter}")
    Sleep(250)
    Send("\")
    Sleep(250)
}

; ========================================================================================
; Functions - Script Phases
; ========================================================================================
RunStartupPhase() {
    global ActionInProgress, IsRunning
    
    if !IsRunning
        return
    
    Sleep(1000)
    
    ; Set Deck 1
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    Sleep(1000)
    NavigateToCommandTask()
    Sleep(250)
    NavigateToDeck1()
    Sleep(250)
    NavigateToTask(Deck1Task)
    Sleep(2500)
    
    ; Set Deck 2
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    Sleep(1000)
    NavigateToCommandTask()
    Sleep(250)
    NavigateToDeck2()
    Sleep(250)
    NavigateToTask(Deck2Task)
    Sleep(2500)
    
    ; Set Deck 3
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    Sleep(1000)
    NavigateToCommandTask()
    Sleep(250)
    NavigateToDeck3()
    Sleep(250)
    NavigateToTask(Deck3Task)
    Sleep(2500)
    
    ; Set Deck 4
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    Sleep(1000)
    NavigateToCommandTask()
    Sleep(250)
    NavigateToDeck4()
    Sleep(250)
    NavigateToTask(Deck4Task)
    Sleep(2500)
    
    ; Set Fleet Risk
    Send(RavenKey)
    ClickCenter()
    Sleep(1000)
    NavigateToFleetRisk()
    Sleep(250)
    
    if (FleetRisk = "Maximize Profit")
        NavigateToMaximizeProfit()
    else
        NavigateToMinimizeProfit()
    
    Sleep(250)
    
    ; Initial Restock if Maximize Profit
    if (FleetRisk = "Maximize Profit") {
        Send(RavenKey)
        Sleep(50)
        ClickCenter()
        Sleep(150)
        NavigateToRestock()
        Sleep(50)
        NavigateToYes()
        Sleep(50)
    }
    
    ActionInProgress := false
    
    ; Start main timers
    StartMainLoop()
}

StartMainLoop() {
    global RecoverRestockTimerObj, RepairTimerObj
    
    ; Start Recover & Restock Timer
    RecoverRestockTimerObj := () => OnRecoverRestockTimer()
    SetTimer(RecoverRestockTimerObj, RecoverRestockTimer * 1000)
    
    ; Start Repair Timer
    RepairTimerObj := () => OnRepairTimer()
    SetTimer(RepairTimerObj, RepairTimer * 1000)
}

OnRecoverRestockTimer() {
    global IsRunning, ActionInProgress, RecoverRestockTimerActive
    
    if !IsRunning || !RecoverRestockTimerActive
        return
    
    ; Wait if action is in progress
    while ActionInProgress && IsRunning {
        Sleep(100)
    }
    
    if !IsRunning
        return
    
    ActionInProgress := true
    
    ; Set Deck 1 to Petrol/Plunder
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    Sleep(1000)
    NavigateToCommandTask()
    Sleep(250)
    NavigateToDeck1()
    Sleep(250)
    NavigateToTask("Petrol/Plunder")
    Sleep(2500)
    
    ; Set Deck 2 to Recover
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    Sleep(1000)
    NavigateToCommandTask()
    Sleep(250)
    NavigateToDeck2()
    Sleep(250)
    NavigateToTask("Recover")
    Sleep(2500)
    
    ; Set Deck 3 to Recover
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    Sleep(1000)
    NavigateToCommandTask()
    Sleep(250)
    NavigateToDeck3()
    Sleep(250)
    NavigateToTask("Recover")
    Sleep(2500)
    
    ; Set Deck 4 to Recover
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    Sleep(1000)
    NavigateToCommandTask()
    Sleep(250)
    NavigateToDeck4()
    Sleep(250)
    NavigateToTask("Recover")
    Sleep(2500)
    
    ; Restock if Maximize Profit
    if (FleetRisk = "Maximize Profit") {
        Send(RavenKey)
        Sleep(250)
        ClickCenter()
        Sleep(1000)
        NavigateToRestock()
        Sleep(250)
        NavigateToYes()
        Sleep(250)
    }
    
    ; Switch timers
    global RecoverRestockTimerActive := false
    global SettingBackTimerActive := true
    SetTimer(RecoverRestockTimerObj, 0)
    
    global SettingBackTimerObj := () => OnSettingBackTimer()
    SetTimer(SettingBackTimerObj, SettingBackTimer * 1000)
    
    ActionInProgress := false
    
    ; Check if repair is pending
    if PendingRepair {
        ExecuteRepair()
    }
}

OnSettingBackTimer() {
    global IsRunning, ActionInProgress, SettingBackTimerActive
    
    if !IsRunning || !SettingBackTimerActive
        return
    
    ; Wait if action is in progress
    while ActionInProgress && IsRunning {
        Sleep(100)
    }
    
    if !IsRunning
        return
    
    ActionInProgress := true
    
    ; Restore Deck 1
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    Sleep(1000)
    NavigateToCommandTask()
    Sleep(250)
    NavigateToDeck1()
    Sleep(250)
    NavigateToTask(Deck1Task)
    Sleep(2500)
    
    ; Restore Deck 2
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    Sleep(1000)
    NavigateToCommandTask()
    Sleep(250)
    NavigateToDeck2()
    Sleep(250)
    NavigateToTask(Deck2Task)
    Sleep(2500)
    
    ; Restore Deck 3
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    Sleep(1000)
    NavigateToCommandTask()
    Sleep(250)
    NavigateToDeck3()
    Sleep(250)
    NavigateToTask(Deck3Task)
    Sleep(2500)
    
    ; Restore Deck 4
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    Sleep(1000)
    NavigateToCommandTask()
    Sleep(250)
    NavigateToDeck4()
    Sleep(250)
    NavigateToTask(Deck4Task)
    Sleep(2500)

    ; Restock if Maximize Profit
    if (FleetRisk = "Maximize Profit") {
        Send(RavenKey)
        Sleep(250)
        ClickCenter()
        Sleep(1000)
        NavigateToRestock()
        Sleep(250)
        NavigateToYes()
        Sleep(250)
    }
    
    ; Switch timers
    global SettingBackTimerActive := false
    global RecoverRestockTimerActive := true
    SetTimer(SettingBackTimerObj, 0)
    
    global RecoverRestockTimerObj := () => OnRecoverRestockTimer()
    SetTimer(RecoverRestockTimerObj, RecoverRestockTimer * 1000)
    
    ActionInProgress := false
    
    ; Check if repair is pending
    if PendingRepair {
        ExecuteRepair()
    }
}

OnRepairTimer() {
    global IsRunning, ActionInProgress, PendingRepair
    
    if !IsRunning
        return
    
    if ActionInProgress {
        PendingRepair := true
        return
    }
    
    ExecuteRepair()
}

ExecuteRepair() {
    global ActionInProgress, PendingRepair, IsRunning
    
    if !IsRunning
        return
    
    ActionInProgress := true
    PendingRepair := false
    
    Send(FleetKey)
    Sleep(1250)
    NavigateToRepairShip()
    Sleep(1250)
    Send(FleetKey)
    Sleep(250)
    
    ActionInProgress := false
}
