#Requires AutoHotkey v2.0
#SingleInstance Force

; ══════════════════════════════════════════════
;  Discord Message Timer
;  Відстежує відправлення повідомлень у Discord
;  і показує таймер + лічильник у окремому вікні
; ══════════════════════════════════════════════

; --- Налаштування ---
WINDOW_TITLE    := "Discord Timer"
TIMER_INTERVAL  := 1000          ; оновлення кожну секунду
WIN_W           := 340
WIN_H           := 310
WIN_X           := A_ScreenWidth - WIN_W - 20
WIN_Y           := 60

; --- Стани ---
global g_elapsed   := 0          ; секунди з останнього повідомлення
global g_msgCount  := 0          ; кількість відправлених повідомлень
global g_paused    := false
global g_started   := false       ; чи було хоча б одне повідомлення
global g_logTimes  := []          ; лог часових міток (до 5 записів)
global g_logGaps   := []          ; лог пауз між повідомленнями

; ══════════════════════════════════════════════
;  GUI
; ══════════════════════════════════════════════
myGui := Gui("+AlwaysOnTop -MaximizeBox +ToolWindow", WINDOW_TITLE)
myGui.BackColor := "1e1f22"
myGui.SetFont("s10 c808080 w400", "Segoe UI")

; --- Верхній рядок: поточний час + лічильник ---
myGui.SetFont("s9 cA0A7B4", "Segoe UI")
myGui.Add("Text", "x14 y14 w140 h16", "Поточний час")
myGui.Add("Text", "x186 y14 w140 h16", "Повідомлень надіслано")

myGui.SetFont("s16 cFFFFFF w500", "Segoe UI")
global ctrlClock := myGui.Add("Text", "x14 y30 w150 h28 +0x200", "00:00:00")

myGui.SetFont("s16 c7F77DD w500", "Segoe UI")
global ctrlCount := myGui.Add("Text", "x186 y30 w150 h28 +0x200", "0")

; --- Роздільник ---
myGui.Add("Text", "x14 y66 w312 h1 +0x10 Background2b2d31")  ; лінія

; --- Головний таймер ---
myGui.SetFont("s9 cA0A7B4", "Segoe UI")
myGui.Add("Text", "x14 y74 w312 h16 +Center", "з останнього повідомлення в Discord")

myGui.SetFont("s38 cFFFFFF w500", "Segoe UI Semibold")
global ctrlTimer := myGui.Add("Text", "x14 y90 w312 h56 +Center", "--:--:--")

; --- Статус-рядок ---
myGui.SetFont("s9 c808080 w400", "Segoe UI")
global ctrlStatus := myGui.Add("Text", "x14 y148 w312 h16 +Center", "○ очікування першого повідомлення")

; --- Роздільник ---
myGui.Add("Text", "x14 y170 w312 h1 +0x10 Background2b2d31")

; --- Заголовок логу ---
myGui.SetFont("s9 cA0A7B4", "Segoe UI")
myGui.Add("Text", "x14 y178 w312 h14", "Останні повідомлення")

; --- Лог (5 рядків) ---
myGui.SetFont("s9 cFFFFFF w400", "Segoe UI")
global ctrlLog := []
Loop 5 {
    ctrlLog.Push(myGui.Add("Text", "x14 y" (192 + (A_Index-1)*18) " w312 h16", ""))
}

; --- Кнопки ---
myGui.SetFont("s9 cA09AD9 w400", "Segoe UI")
global btnPause := myGui.Add("Button", "x14 y282 w100 h22", "Пауза")
myGui.Add("Button", "x122 y282 w100 h22", "Скинути")
myGui.Add("Button", "x230 y282 w96 h22", "Очистити лог")

btnPause.OnEvent("Click", TogglePause)
myGui["Button2"].OnEvent("Click", ResetTimer)
myGui["Button3"].OnEvent("Click", ClearLog)

myGui.OnEvent("Close", (*) => ExitApp())

myGui.Show("x" WIN_X " y" WIN_Y " w" WIN_W " h" WIN_H)

; ══════════════════════════════════════════════
;  Хук на клавіатуру (глобальний)
;  Спрацьовує на Enter у вікні Discord
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

    isDiscordApp := (activeExe = "Discord.exe")

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
;  Таймери
; ══════════════════════════════════════════════
SetTimer(UpdateClock, TIMER_INTERVAL)
SetTimer(UpdateTimer, TIMER_INTERVAL)

; ══════════════════════════════════════════════
;  Функції
; ══════════════════════════════════════════════

OnMessage_Sent() {
    global g_elapsed, g_msgCount, g_logTimes, g_logGaps, g_started

    ; Перше повідомлення — активуємо таймер
    if (!g_started) {
        g_started := true
        ctrlStatus.Text := "● моніторинг активний"
        ctrlStatus.Opt("c534AB7")
    }

    g_msgCount++

    now := FormatTime(, "HH:mm:ss")
    gap := g_elapsed

    ; Додаємо до логу
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
    btnPause.Text := g_paused ? "Продовжити" : "Пауза"
    ctrlStatus.Text := g_paused ? "⏸ пауза" : "● моніторинг активний"
    ctrlStatus.Opt(g_paused ? "cFebc2e" : "c534AB7")
}

ClearLog(*) {
    global g_logTimes, g_logGaps, g_msgCount, g_elapsed, g_started
    g_logTimes  := []
    g_logGaps   := []
    g_msgCount  := 0
    g_elapsed   := 0
    g_started   := false
    ctrlStatus.Text := "○ очікування першого повідомлення"
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

    ; Головний таймер
    if (!g_started) {
        ctrlTimer.Text := "--:--:--"
        ctrlTimer.Opt("c444441")
    } else {
        ctrlTimer.Text := SecsToHMS(g_elapsed)
        ; Колір таймера — зеленуватий якщо < 2 хв, жовтий < 5 хв, червоний далі
        if (g_elapsed < 120)
            ctrlTimer.Opt("c7BDD9B")
        else if (g_elapsed < 300)
            ctrlTimer.Opt("cEF9F27")
        else
            ctrlTimer.Opt("cE24B4A")
    }

    ; Лічильник
    ctrlCount.Text := g_msgCount

    ; Лог
    Loop 5 {
        if (A_Index <= g_logTimes.Length) {
            ts  := g_logTimes[A_Index]
            gap := g_logGaps[A_Index]
            ctrlLog[A_Index].Text := "#" (g_msgCount - A_Index + 1)
                . "   " ts
                . "   пауза: " FormatGap(gap)
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
        return s "с"
    return (s // 60) "хв " Mod(s, 60) "с"
}
