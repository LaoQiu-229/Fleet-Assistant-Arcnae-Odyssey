#Requires AutoHotkey v2.0
#SingleInstance Force

; ========================================================================================
; Global Variables - GUI Controls
; ========================================================================================
global GuiObj := ""
global StatusGuiObj := ""
global RavenKeyInput := ""
global FleetKeyInput := ""
global NavigationKeyInput := ""
global FleetRiskDropdown := ""
global Deck1Dropdown := ""
global Deck2Dropdown := ""
global Deck3Dropdown := ""
global Deck4Dropdown := ""
global RepairWaitInput := ""
global RecoverTimerInput := ""
global ResuppliesTimerInput := ""
global RepairTimerInput := ""
global ResumeTaskTimerInput := ""

; ========================================================================================
; Global Variables - Settings
; ========================================================================================
global RavenKey := "8"
global FleetKey := "y"
global NavigationKey := "\"
global FleetRisk := "Maximize Profit"
global Deck1Task := "Trading"
global Deck2Task := "Trading"
global Deck3Task := "Recover"
global Deck4Task := "Recover"
global RepairWaitTime := 3000
global RecoverTimer := 5400
global ResuppliesTimer := 300
global RepairTimer := 300
global ResumeTaskTimer := 600

; ========================================================================================
; Global Variables - State Management
; ========================================================================================
global IsRunning := false
global ActionInProgress := false
global ResuppliesInProgress := false
global PendingRepair := false
global PendingResupplies := false
global RecoverTimerActive := true
global ResumeTaskTimerActive := false

; ========================================================================================
; Global Variables - Timer Objects
; ========================================================================================
global RecoverTimerObj := ""
global ResuppliesTimerObj := ""
global RepairTimerObj := ""
global ResumeTaskTimerObj := ""
global TooltipUpdateTimer := ""

; ========================================================================================
; Global Variables - Timer Tracking
; ========================================================================================
global StartTime := 0
global LastRepairTime := 0
global LastResuppliesTime := 0
global LastRecoverTime := 0
global LastResumeTaskTime := 0

; ========================================================================================
; Load Settings on Startup
; ========================================================================================
LoadSettings()

; ========================================================================================
; Create GUI
; ========================================================================================
CreateGUI()
CreateStatusGUI()

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
                case "NavigationKey": global NavigationKey := value
                case "FleetRisk": global FleetRisk := value
                case "Deck1Task": global Deck1Task := value
                case "Deck2Task": global Deck2Task := value
                case "Deck3Task": global Deck3Task := value
                case "Deck4Task": global Deck4Task := value
                case "RepairWaitTime": global RepairWaitTime := Integer(value)
                case "RecoverTimer": global RecoverTimer := Integer(value)
                case "ResuppliesTimer": global ResuppliesTimer := Integer(value)
                case "RepairTimer": global RepairTimer := Integer(value)
                case "ResumeTaskTimer": global ResumeTaskTimer := Integer(value)
            }
        }
    }
}

SaveSettings(*) {
    settingFile := A_ScriptDir . "\Setting.txt"
    
    ; Get current values from GUI
    global RavenKey := RavenKeyInput.Value
    global FleetKey := FleetKeyInput.Value
    global NavigationKey := NavigationKeyInput.Value
    global FleetRisk := FleetRiskDropdown.Text
    global Deck1Task := Deck1Dropdown.Text
    global Deck2Task := Deck2Dropdown.Text
    global Deck3Task := Deck3Dropdown.Text
    global Deck4Task := Deck4Dropdown.Text
    global RepairWaitTime := Integer(RepairWaitInput.Value)
    global RecoverTimer := Integer(RecoverTimerInput.Value)
    global ResuppliesTimer := Integer(ResuppliesTimerInput.Value)
    global RepairTimer := Integer(RepairTimerInput.Value)
    global ResumeTaskTimer := Integer(ResumeTaskTimerInput.Value)
    
    content := ""
    content .= "RavenKey=" . RavenKey . "`n"
    content .= "FleetKey=" . FleetKey . "`n"
    content .= "NavigationKey=" . NavigationKey . "`n"
    content .= "FleetRisk=" . FleetRisk . "`n"
    content .= "Deck1Task=" . Deck1Task . "`n"
    content .= "Deck2Task=" . Deck2Task . "`n"
    content .= "Deck3Task=" . Deck3Task . "`n"
    content .= "Deck4Task=" . Deck4Task . "`n"
    content .= "RepairWaitTime=" . RepairWaitTime . "`n"
    content .= "RecoverTimer=" . RecoverTimer . "`n"
    content .= "ResuppliesTimer=" . ResuppliesTimer . "`n"
    content .= "RepairTimer=" . RepairTimer . "`n"
    content .= "ResumeTaskTimer=" . ResumeTaskTimer . "`n"
    
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
    yPos += 35
    
    GuiObj.Add("Text", "x20 y" . yPos . " w120", "Navigation Key:")
    global NavigationKeyInput := GuiObj.Add("Edit", "x140 y" . yPos . " w100", NavigationKey)
    NavigationKeyInput.SetFont("s9 c0x000000")
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
    GuiObj.Add("Text", "x250 y" . (yPos + 2) . " w140", "1sec = 1000ms").SetFont("s8 c0x666666")
    yPos += 45
    
    GuiObj.Add("Text", "x20 y" . yPos . " w120", "Recover Timer:")
    global RecoverTimerInput := GuiObj.Add("Edit", "x140 y" . yPos . " w100", RecoverTimer)
    RecoverTimerInput.SetFont("s9 c0x000000")
    GuiObj.Add("Text", "x250 y" . (yPos + 2) . " w100", "seconds").SetFont("s8 c0x666666")
    yPos += 35
    
    GuiObj.Add("Text", "x20 y" . yPos . " w120", "Resume Task Timer:")
    global ResumeTaskTimerInput := GuiObj.Add("Edit", "x140 y" . yPos . " w100", ResumeTaskTimer)
    ResumeTaskTimerInput.SetFont("s9 c0x000000")
    GuiObj.Add("Text", "x250 y" . (yPos + 2) . " w100", "seconds").SetFont("s8 c0x666666")
    yPos += 35
    
    GuiObj.Add("Text", "x20 y" . yPos . " w120", "Resupplies Timer:")
    global ResuppliesTimerInput := GuiObj.Add("Edit", "x140 y" . yPos . " w100", ResuppliesTimer)
    ResuppliesTimerInput.SetFont("s9 c0x000000")
    GuiObj.Add("Text", "x250 y" . (yPos + 2) . " w100", "seconds").SetFont("s8 c0x666666")
    yPos += 35
    
    GuiObj.Add("Text", "x20 y" . yPos . " w120", "Repair Timer:")
    global RepairTimerInput := GuiObj.Add("Edit", "x140 y" . yPos . " w100", RepairTimer)
    RepairTimerInput.SetFont("s9 c0x000000")
    GuiObj.Add("Text", "x250 y" . (yPos + 2) . " w100", "seconds").SetFont("s8 c0x666666")
    yPos += 45
    
    ; Save Button
    saveBtn := GuiObj.Add("Button", "x20 y" . yPos . " w360 h35", "💾 SAVE SETTINGS")
    saveBtn.SetFont("s10 Bold c0x000000")
    saveBtn.OnEvent("Click", SaveSettings)
    yPos += 45

    ; Function Key
    GuiObj.Add("Text", "x20 y" . yPos . " w360", "F1: Start  F2:  Reload F3:  Exit").SetFont("s9 c0x888888")
    yPos += 20
    
    ; Position at top-left
    GuiObj.Show("x0 y0 w400 h" . yPos)
}

CreateStatusGUI() {
    global StatusGuiObj := Gui("-Caption +AlwaysOnTop +ToolWindow +Disabled", "Fleet Status")
    StatusGuiObj.BackColor := "0x1A1A1A"
    StatusGuiObj.SetFont("s9 c0xFFFFFF", "Consolas")
    
    ; Status display will be updated via tooltip instead
    StatusGuiObj.Hide()
}

; ========================================================================================
; Functions - Script Control
; ========================================================================================
StartScript() {
    global IsRunning, ActionInProgress, StartTime
    
    if IsRunning {
        MsgBox("Script is already running!", "Fleet Assistant", "0x30")
        return
    }
    
    IsRunning := true
    ActionInProgress := true
    StartTime := A_TickCount
    
    ; Initialize timer tracking
    global LastRecoverTime := A_TickCount
    global LastResuppliesTime := A_TickCount
    global LastRepairTime := A_TickCount
    global LastResumeTaskTime := 0
    
    ; Start tooltip update timer
    global TooltipUpdateTimer := () => UpdateTooltip()
    SetTimer(TooltipUpdateTimer, 500)
    
    ; Execute startup phase
    ExecuteStartupPhase()
}

ExitScript(*) {
    global IsRunning := false
    
    ; Stop all timers
    if (RecoverTimerObj != "")
        SetTimer(RecoverTimerObj, 0)
    if (ResuppliesTimerObj != "")
        SetTimer(ResuppliesTimerObj, 0)
    if (RepairTimerObj != "")
        SetTimer(RepairTimerObj, 0)
    if (ResumeTaskTimerObj != "")
        SetTimer(ResumeTaskTimerObj, 0)
    if (TooltipUpdateTimer != "")
        SetTimer(TooltipUpdateTimer, 0)
    
    ; Clear tooltip
    ToolTip()
    
    ExitApp
}

; ========================================================================================
; Functions - Tooltip Update
; ========================================================================================
UpdateTooltip() {
    global IsRunning, StartTime, LastRepairTime, LastResuppliesTime, LastRecoverTime, LastResumeTaskTime
    global RecoverTimer, ResuppliesTimer, RepairTimer, ResumeTaskTimer
    global RecoverTimerActive, ResumeTaskTimerActive
    
    if !IsRunning {
        ToolTip()
        return
    }
    
    currentTime := A_TickCount
    
    ; Calculate running time
    elapsedMs := currentTime - StartTime
    hours := Floor(elapsedMs / 3600000)
    minutes := Floor(Mod(elapsedMs, 3600000) / 60000)
    seconds := Floor(Mod(elapsedMs, 60000) / 1000)
    runningTime := Format("{:02d}:{:02d}:{:02d}", hours, minutes, seconds)
    
    ; Calculate next Recover (only if active)
    if RecoverTimerActive {
        recoverRemaining := (RecoverTimer * 1000) - (currentTime - LastRecoverTime)
        if (recoverRemaining < 0)
            recoverRemaining := 0
        recoverMin := Floor(recoverRemaining / 60000)
        recoverSec := Floor(Mod(recoverRemaining, 60000) / 1000)
        nextRecover := Format("{:02d}:{:02d}", recoverMin, recoverSec)
    } else {
        nextRecover := "--"
    }
    
    ; Calculate next Resume Task (only if active)
    if ResumeTaskTimerActive {
        resumeRemaining := (ResumeTaskTimer * 1000) - (currentTime - LastResumeTaskTime)
        if (resumeRemaining < 0)
            resumeRemaining := 0
        resumeMin := Floor(resumeRemaining / 60000)
        resumeSec := Floor(Mod(resumeRemaining, 60000) / 1000)
        nextResume := Format("{:02d}:{:02d}", resumeMin, resumeSec)
    } else {
        nextResume := "--"
    }
    
    ; Calculate next Resupplies
    resuppliesRemaining := (ResuppliesTimer * 1000) - (currentTime - LastResuppliesTime)
    if (resuppliesRemaining < 0)
        resuppliesRemaining := 0
    resuppliesMin := Floor(resuppliesRemaining / 60000)
    resuppliesSec := Floor(Mod(resuppliesRemaining, 60000) / 1000)
    nextResupplies := Format("{:02d}:{:02d}", resuppliesMin, resuppliesSec)
    
    ; Calculate next Repair
    repairRemaining := (RepairTimer * 1000) - (currentTime - LastRepairTime)
    if (repairRemaining < 0)
        repairRemaining := 0
    repairMin := Floor(repairRemaining / 60000)
    repairSec := Floor(Mod(repairRemaining, 60000) / 1000)
    nextRepair := Format("{:02d}:{:02d}", repairMin, repairSec)
    
    ; Build tooltip text (Order: Recover > Resume > Resupplies > Repair)
    tooltipText := "⚓ Fleet Assistant Status`n"
    tooltipText .= "━━━━━━━━━━━━━━━━━━━━━━`n"
    tooltipText .= "Running Time: " . runningTime . "`n"
    tooltipText .= "━━━━━━━━━━━━━━━━━━━━━━`n"
    tooltipText .= "Next Recover: " . nextRecover . "`n"
    tooltipText .= "Next Resume: " . nextResume . "`n"
    tooltipText .= "Next Resupplies: " . nextResupplies . "`n"
    tooltipText .= "Next Repair: " . nextRepair
    
    ; Display tooltip at top-right
    ToolTip(tooltipText, A_ScreenWidth - 250, 0)
}

; ========================================================================================
; Functions - Navigation Core
; ========================================================================================
NavigateToStartArea() {
    Send(NavigationKey)
    Sleep(100)
    
    Loop 20 {
        Send("w")
        Sleep(25)
    }
    
    Sleep(100)
}

ClickCenter() {
    screenWidth := A_ScreenWidth
    screenHeight := A_ScreenHeight
    centerX := screenWidth / 2
    centerY := screenHeight / 2
    Click(centerX, centerY)
    Sleep(1250)
}

; ========================================================================================
; Functions - Navigation to Menus
; ========================================================================================
NavigateToCommandTask() {
    NavigateToStartArea()
    Sleep(100)
    Send("s")
    Sleep(100)
    Send("{Enter}")
    Sleep(100)
    Send(NavigationKey)
    Sleep(100)
}

NavigateToResupplies() {
    NavigateToStartArea()
    Sleep(100)
    Send("s")
    Sleep(100)
    Send("d")
    Sleep(100)
    Send("{Enter}")
    Sleep(100)
    Send(NavigationKey)
    Sleep(100)
}

NavigateToFleetRisk() {
    NavigateToStartArea()
    Sleep(100)
    Send("s")
    Sleep(100)
    Send("d")
    Sleep(100)
    Send("d")
    Sleep(100)
    Send("{Enter}")
    Sleep(100)
    Send(NavigationKey)
    Sleep(100)
}

NavigateToDeck1() {
    NavigateToStartArea()
    Sleep(100)
    Send("s")
    Sleep(100)
    Send("{Enter}")
    Sleep(100)
    Send(NavigationKey)
    Sleep(100)
}

NavigateToDeck2() {
    NavigateToStartArea()
    Sleep(100)
    Send("s")
    Sleep(100)
    Send("d")
    Sleep(100)
    Send("{Enter}")
    Sleep(100)
    Send(NavigationKey)
    Sleep(100)
}

NavigateToDeck3() {
    NavigateToStartArea()
    Sleep(100)
    Send("s")
    Sleep(100)
    Send("d")
    Sleep(100)
    Send("d")
    Sleep(100)
    Send("{Enter}")
    Sleep(100)
    Send(NavigationKey)
    Sleep(100)
}

NavigateToDeck4() {
    NavigateToStartArea()
    Sleep(100)
    Send("s")
    Sleep(100)
    Send("d")
    Sleep(100)
    Send("d")
    Sleep(100)
    Send("d")
    Sleep(100)
    Send("{Enter}")
    Sleep(100)
    Send(NavigationKey)
    Sleep(100)
}

NavigateToRepairShip() {
    NavigateToStartArea()
    Sleep(100)
    Send("s")
    Sleep(100)
    Send("s")
    Sleep(100)
    Send("s")
    Sleep(100)
    Send("s")
    Sleep(100)
    Send("d")
    Sleep(100)
    Send("{Enter}")
    Sleep(RepairWaitTime)
    Send("w")
    Sleep(100)
    Send("w")
    Sleep(100)
    Send("w")
    Sleep(100)
    Send("s")
    Sleep(100)
    Send("w")
    Sleep(100)
    Send("{Enter}")
    Sleep(100)
    Send(NavigationKey)
    Sleep(100)
}

; ========================================================================================
; Functions - Navigation to Tasks
; ========================================================================================
NavigateToTask(taskName) {
    NavigateToStartArea()
    Sleep(100)
    Send("d")
    Sleep(100)
    
    switch taskName {
        case "Exploring":
            ; Already at Exploring (d)
            
        case "Recover":
            Send("s")
            Sleep(100)
            
        case "Petrol/Plunder":
            Send("s")
            Sleep(100)
            Send("s")
            Sleep(100)
            
        case "Fishing":
            Send("s")
            Sleep(100)
            Send("s")
            Sleep(100)
            Send("s")
            Sleep(100)
            
        case "Harvesting":
            Send("s")
            Sleep(100)
            Send("s")
            Sleep(100)
            Send("s")
            Sleep(100)
            Send("s")
            Sleep(100)
            
        case "Conquest":
            Send("s")
            Sleep(100)
            Send("s")
            Sleep(100)
            Send("s")
            Sleep(100)
            Send("s")
            Sleep(100)
            Send("s")
            Sleep(100)
            
        case "Trading":
            Send("s")
            Sleep(100)
            Send("s")
            Sleep(100)
            Send("s")
            Sleep(100)
            Send("s")
            Sleep(100)
            Send("s")
            Sleep(100)
            Send("s")
            Sleep(100)
    }
    
    Send("{Enter}")
    Sleep(100)
    Send(NavigationKey)
    Sleep(100)
}

; ========================================================================================
; Functions - Navigation to Special Actions
; ========================================================================================
NavigateToYes() {
    NavigateToStartArea()
    Sleep(100)
    Send("d")
    Sleep(100)
    Send("s")
    Sleep(100)
    Send("a")
    Sleep(100)
    Send("{Enter}")
    Sleep(100)
    Send(NavigationKey)
    Sleep(100)
}

NavigateToMaximizeProfit() {
    NavigateToStartArea()
    Sleep(100)
    Send("d")
    Sleep(100)
    Send("{Enter}")
    Sleep(100)
    Send(NavigationKey)
    Sleep(100)
}

NavigateToMinimizeProfit() {
    NavigateToStartArea()
    Sleep(100)
    Send("d")
    Sleep(100)
    Send("s")
    Sleep(100)
    Send("{Enter}")
    Sleep(100)
    Send(NavigationKey)
    Sleep(100)
}

; ========================================================================================
; Functions - Startup Phase
; ========================================================================================
ExecuteStartupPhase() {
    global ActionInProgress, IsRunning
    
    if !IsRunning
        return
    
    Sleep(1000)
    
    ; Set Deck 1
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    NavigateToCommandTask()
    NavigateToDeck1()
    NavigateToTask(Deck1Task)
    Sleep(2500)
    
    if !IsRunning
        return
    
    ; Set Deck 2
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    NavigateToCommandTask()
    NavigateToDeck2()
    NavigateToTask(Deck2Task)
    Sleep(2500)
    
    if !IsRunning
        return
    
    ; Set Deck 3
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    NavigateToCommandTask()
    NavigateToDeck3()
    NavigateToTask(Deck3Task)
    Sleep(2500)
    
    if !IsRunning
        return
    
    ; Set Deck 4
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    NavigateToCommandTask()
    NavigateToDeck4()
    NavigateToTask(Deck4Task)
    Sleep(2500)
    
    if !IsRunning
        return
    
    ; Set Fleet Risk
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    NavigateToFleetRisk()
    
    if (FleetRisk = "Maximize Profit")
        NavigateToMaximizeProfit()
    else
        NavigateToMinimizeProfit()
    
    Sleep(2500)
    
    ActionInProgress := false
    
    ; Start main loop timers
    StartMainLoop()
}

; ========================================================================================
; Functions - Main Loop
; ========================================================================================
StartMainLoop() {
    global RecoverTimerObj, ResuppliesTimerObj, RepairTimerObj
    global RecoverTimerActive, LastRecoverTime, LastResuppliesTime, LastRepairTime
    
    ; Initialize timer states
    RecoverTimerActive := true
    LastRecoverTime := A_TickCount
    LastResuppliesTime := A_TickCount
    LastRepairTime := A_TickCount
    
    ; Start Recover Timer
    RecoverTimerObj := () => OnRecoverTimer()
    SetTimer(RecoverTimerObj, RecoverTimer * 1000)
    
    ; Start Resupplies Timer (independent)
    ResuppliesTimerObj := () => OnResuppliesTimer()
    SetTimer(ResuppliesTimerObj, ResuppliesTimer * 1000)
    
    ; Start Repair Timer (independent)
    RepairTimerObj := () => OnRepairTimer()
    SetTimer(RepairTimerObj, RepairTimer * 1000)
}

; ========================================================================================
; Timer Event 1: Recover Timer
; ========================================================================================
OnRecoverTimer() {
    global IsRunning, ActionInProgress, RecoverTimerActive, ResumeTaskTimerActive
    
    if !IsRunning || !RecoverTimerActive
        return
    
    ; Wait if action is in progress
    while ActionInProgress && IsRunning {
        Sleep(100)
    }
    
    if !IsRunning
        return
    
    ActionInProgress := true
    
    ; Set Deck 1 to Recover
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    NavigateToCommandTask()
    NavigateToDeck1()
    NavigateToTask("Recover")
    Sleep(2500)
    
    if !IsRunning {
        ActionInProgress := false
        return
    }
    
    ; Set Deck 2 to Recover
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    NavigateToCommandTask()
    NavigateToDeck2()
    NavigateToTask("Recover")
    Sleep(2500)
    
    if !IsRunning {
        ActionInProgress := false
        return
    }
    
    ; Set Deck 3 to Recover
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    NavigateToCommandTask()
    NavigateToDeck3()
    NavigateToTask("Recover")
    Sleep(2500)
    
    if !IsRunning {
        ActionInProgress := false
        return
    }
    
    ; Set Deck 4 to Recover
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    NavigateToCommandTask()
    NavigateToDeck4()
    NavigateToTask("Recover")
    Sleep(2500)
    
    ; Switch to Resume Task Timer
    global RecoverTimerActive := false
    global ResumeTaskTimerActive := true
    global LastResumeTaskTime := A_TickCount
    SetTimer(RecoverTimerObj, 0)
    
    global ResumeTaskTimerObj := () => OnResumeTaskTimer()
    SetTimer(ResumeTaskTimerObj, ResumeTaskTimer * 1000)
    
    ActionInProgress := false
    
    ; Check if repair or resupplies are pending
    if PendingResupplies {
        ExecuteResupplies()
    } else if PendingRepair {
        ExecuteRepair()
    }
}

; ========================================================================================
; Timer Event 2: Repair Timer
; ========================================================================================
OnRepairTimer() {
    global IsRunning, ActionInProgress, ResuppliesInProgress, PendingRepair
    
    if !IsRunning
        return
    
    ; Check if Resupplies is in progress
    if ResuppliesInProgress {
        PendingRepair := true
        return
    }
    
    ; Check if other actions are in progress
    if ActionInProgress {
        PendingRepair := true
        return
    }
    
    ExecuteRepair()
}

ExecuteRepair() {
    global ActionInProgress, PendingRepair, IsRunning, LastRepairTime
    
    if !IsRunning
        return
    
    ActionInProgress := true
    PendingRepair := false
    
    Send(FleetKey)
    Sleep(1250)
    NavigateToRepairShip()
    Send(FleetKey)
    Sleep(250)
    
    ; Update last repair time
    global LastRepairTime := A_TickCount
    
    ActionInProgress := false
}

; ========================================================================================
; Timer Event 3: Resupplies Timer
; ========================================================================================
OnResuppliesTimer() {
    global IsRunning, ActionInProgress, PendingResupplies, FleetRisk
    
    if !IsRunning
        return
    
    ; Skip if Minimize Profit mode
    if (FleetRisk = "Minimize Profit")
        return
    
    ; Check if other actions are in progress
    if ActionInProgress {
        PendingResupplies := true
        return
    }
    
    ExecuteResupplies()
}

ExecuteResupplies() {
    global ActionInProgress, ResuppliesInProgress, PendingResupplies, PendingRepair
    global IsRunning, LastResuppliesTime, FleetRisk
    
    if !IsRunning
        return
    
    ; Skip if Minimize Profit mode
    if (FleetRisk = "Minimize Profit") {
        PendingResupplies := false
        return
    }
    
    ActionInProgress := true
    ResuppliesInProgress := true
    PendingResupplies := false
    
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    NavigateToResupplies()
    Sleep(500)
    NavigateToYes()
    
    ; Update last resupplies time
    global LastResuppliesTime := A_TickCount
    
    ResuppliesInProgress := false
    ActionInProgress := false
    
    ; Execute pending repair if flagged
    if PendingRepair {
        Sleep(1000)
        ExecuteRepair()
    }
}

; ========================================================================================
; Timer Event 4: Resume Task Timer
; ========================================================================================
OnResumeTaskTimer() {
    global IsRunning, ActionInProgress, ResumeTaskTimerActive, RecoverTimerActive
    
    if !IsRunning || !ResumeTaskTimerActive
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
    NavigateToCommandTask()
    NavigateToDeck1()
    NavigateToTask(Deck1Task)
    Sleep(2500)
    
    if !IsRunning {
        ActionInProgress := false
        return
    }
    
    ; Restore Deck 2
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    NavigateToCommandTask()
    NavigateToDeck2()
    NavigateToTask(Deck2Task)
    Sleep(2500)
    
    if !IsRunning {
        ActionInProgress := false
        return
    }
    
    ; Restore Deck 3
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    NavigateToCommandTask()
    NavigateToDeck3()
    NavigateToTask(Deck3Task)
    Sleep(2500)
    
    if !IsRunning {
        ActionInProgress := false
        return
    }
    
    ; Restore Deck 4
    Send(RavenKey)
    Sleep(250)
    ClickCenter()
    NavigateToCommandTask()
    NavigateToDeck4()
    NavigateToTask(Deck4Task)
    Sleep(2500)
    
    ; Switch back to Recover Timer
    global ResumeTaskTimerActive := false
    global RecoverTimerActive := true
    global LastRecoverTime := A_TickCount
    SetTimer(ResumeTaskTimerObj, 0)
    
    global RecoverTimerObj := () => OnRecoverTimer()
    SetTimer(RecoverTimerObj, RecoverTimer * 1000)
    
    ActionInProgress := false
    
    ; Check if repair or resupplies are pending
    if PendingResupplies {
        ExecuteResupplies()
    } else if PendingRepair {
        ExecuteRepair()
    }
}
