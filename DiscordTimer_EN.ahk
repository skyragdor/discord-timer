#Requires AutoHotkey v2.0
#SingleInstance Force

; ══════════════════════════════════════════════
;  Discord Message Timer
;  Tracks messages sent in Discord and shows
;  a timer + counter in a floating window
; ══════════════════════════════════════════════

; --- Settings ---
WINDOW_TITLE    := "Discord Timer"
TIMER_INTERVAL  := 1000          ; update every second
WIN_W           := 340
WIN_H           := 310
WIN_X           := A_ScreenWidth - WIN_W - 20
WIN_Y           := 60

; --- State ---
global g_elapsed   := 0          ; seconds since last message
global g_msgCount  := 0          ; total messages sent
global g_paused    := false
global g_started   := false       ; whether at least one message was sent
global g_logTimes  := []          ; log of timestamps (up to 5)
global g_logGaps   := []          ; log of gaps between messages

; ══════════════════════════════════════════════
;  GUI
; ══════════════════════════════════════════════
myGui := Gui("+AlwaysOnTop -MaximizeBox +ToolWindow", WINDOW_TITLE)
myGui.BackColor := "1e1f22"
myGui.SetFont("s10 c808080 w400", "Segoe UI")

; --- Top row: current time + message count ---
myGui.SetFont("s9 cA0A7B4", "Segoe UI")
myGui.Add("Text", "x14 y14 w140 h16", "Current time")
myGui.Add("Text", "x186 y14 w140 h16", "Messages sent")

myGui.SetFont("s16 cFFFFFF w500", "Segoe UI")
global ctrlClock := myGui.Add("Text", "x14 y30 w150 h28 +0x200", "00:00:00")

myGui.SetFont("s16 c7F77DD w500", "Segoe UI")
global ctrlCount := myGui.Add("Text", "x186 y30 w150 h28 +0x200", "0")

; --- Divider ---
myGui.Add("Text", "x14 y66 w312 h1 +0x10 Background2b2d31")

; --- Main timer ---
myGui.SetFont("s9 cA0A7B4", "Segoe UI")
myGui.Add("Text", "x14 y74 w312 h16 +Center", "since last Discord message")

myGui.SetFont("s38 cFFFFFF w500", "Segoe UI Semibold")
global ctrlTimer := myGui.Add("Text", "x14 y90 w312 h56 +Center", "--:--:--")

; --- Status bar ---
myGui.SetFont("s9 c808080 w400", "Segoe UI")
global ctrlStatus := myGui.Add("Text", "x14 y148 w312 h16 +Center", "○ waiting for first message")

; --- Divider ---
myGui.Add("Text", "x14 y170 w312 h1 +0x10 Background2b2d31")

; --- Log header ---
myGui.SetFont("s9 cA0A7B4", "Segoe UI")
myGui.Add("Text", "x14 y178 w312 h14", "Recent messages")

; --- Log (5 rows) ---
myGui.SetFont("s9 cFFFFFF w400", "Segoe UI")
global ctrlLog := []
Loop 5 {
    ctrlLog.Push(myGui.Add("Text", "x14 y" (192 + (A_Index-1)*18) " w312 h16", ""))
}

; --- Buttons ---
myGui.SetFont("s9 cA09AD9 w400", "Segoe UI")
global btnPause := myGui.Add("Button", "x14 y282 w100 h22", "Pause")
myGui.Add("Button", "x122 y282 w100 h22", "Reset")
myGui.Add("Button", "x230 y282 w96 h22", "Clear log")

btnPause.OnEvent("Click", TogglePause)
myGui["Button2"].OnEvent("Click", ResetTimer)
myGui["Button3"].OnEvent("Click", ClearLog)

myGui.OnEvent("Close", (*) => ExitApp())

myGui.Show("x" WIN_X " y" WIN_Y " w" WIN_W " h" WIN_H)

; ══════════════════════════════════════════════
;  Global keyboard hook
;  Fires on Enter inside a Discord window
; ══════════════════════════════════════════════
global g_shiftDown := false

~LShift:: g_shiftDown := true
~RShift:: g_shiftDown := true
~LShift Up:: g_shiftDown := false
~RShift Up:: g_shiftDown := false

~Enter:: {
    activeExe   := ""
    activeTitle := ""
    try activeExe   := WinGetProcessName("A")
    try activeTitle := WinGetTitle("A")

    ; Desktop app
    isDiscordApp := (activeExe = "Discord.exe")

    ; Web version in any browser — window title contains "Discord"
    isBrowser := (activeExe = "chrome.exe"
               || activeExe = "firefox.exe"
               || activeExe = "msedge.exe"
               || activeExe = "opera.exe"
               || activeExe = "brave.exe")
    isDiscordWeb := (isBrowser && InStr(activeTitle, "Discord"))

    if ((isDiscordApp || isDiscordWeb) && !g_shiftDown) {
        OnMessage_Sent()
    }
}

; ══════════════════════════════════════════════
;  Timers
; ══════════════════════════════════════════════
SetTimer(UpdateClock, TIMER_INTERVAL)
SetTimer(UpdateTimer, TIMER_INTERVAL)

; ══════════════════════════════════════════════
;  Functions
; ══════════════════════════════════════════════

OnMessage_Sent() {
    global g_elapsed, g_msgCount, g_logTimes, g_logGaps, g_started

    ; First message — activate the timer
    if (!g_started) {
        g_started := true
        ctrlStatus.Text := "● monitoring active"
        ctrlStatus.Opt("c534AB7")
    }

    g_msgCount++

    now := FormatTime(, "HH:mm:ss")
    gap := g_elapsed

    ; Add to log
    g_logTimes.InsertAt(1, now)
    g_logGaps.InsertAt(1, gap)
    if g_logTimes.Length > 5 {
        g_logTimes.RemoveAt(6)
        g_logGaps.RemoveAt(6)
    }

    g_elapsed := 0
    UpdateUI()
}

ResetTimer(*) {
    global g_elapsed
    g_elapsed := 0
    UpdateUI()
}

TogglePause(*) {
    global g_paused
    g_paused := !g_paused
    btnPause.Text := g_paused ? "Resume" : "Pause"
    ctrlStatus.Text := g_paused ? "⏸ paused" : "● monitoring active"
    ctrlStatus.Opt(g_paused ? "cFebc2e" : "c534AB7")
}

ClearLog(*) {
    global g_logTimes, g_logGaps, g_msgCount, g_elapsed, g_started
    g_logTimes  := []
    g_logGaps   := []
    g_msgCount  := 0
    g_elapsed   := 0
    g_started   := false
    ctrlStatus.Text := "○ waiting for first message"
    ctrlStatus.Opt("c808080")
    UpdateUI()
}

UpdateClock() {
    ctrlClock.Text := FormatTime(, "HH:mm:ss")
}

UpdateTimer() {
    global g_elapsed, g_paused, g_started
    if (g_started && !g_paused) {
        g_elapsed++
        UpdateUI()
    }
}

UpdateUI() {
    global g_started

    ; Main timer
    if (!g_started) {
        ctrlTimer.Text := "--:--:--"
        ctrlTimer.Opt("c444441")
    } else {
        ctrlTimer.Text := SecsToHMS(g_elapsed)
        ; Green < 2 min, yellow < 5 min, red beyond
        if (g_elapsed < 120)
            ctrlTimer.Opt("c7BDD9B")
        else if (g_elapsed < 300)
            ctrlTimer.Opt("cEF9F27")
        else
            ctrlTimer.Opt("cE24B4A")
    }

    ; Message count
    ctrlCount.Text := g_msgCount

    ; Log
    Loop 5 {
        if (A_Index <= g_logTimes.Length) {
            ts  := g_logTimes[A_Index]
            gap := g_logGaps[A_Index]
            ctrlLog[A_Index].Text := "#" (g_msgCount - A_Index + 1)
                . "   " ts
                . "   gap: " FormatGap(gap)
            ctrlLog[A_Index].Opt("cC8C4F0")
        } else {
            ctrlLog[A_Index].Text := ""
        }
    }
}

SecsToHMS(s) {
    h := s // 3600
    m := (s - h*3600) // 60
    sec := Mod(s, 60)
    return Format("{:02d}:{:02d}:{:02d}", h, m, sec)
}

FormatGap(s) {
    if (s < 60)
        return s "s"
    return (s // 60) "m " Mod(s, 60) "s"
}
