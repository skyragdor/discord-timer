# Discord Timer

A lightweight Windows utility that tracks your Discord activity and displays:
- ⏱ Timer since your last sent message
- 🕐 Current time
- 💬 Total messages sent this session
- 📋 Log of the last 5 messages with gaps between them

The window stays always on top and doesn't interfere with anything.

---

## Screenshot

<img width="340" height="343" alt="image" src="https://github.com/user-attachments/assets/f57d9a65-dffc-4dba-ac33-5e6ed15f8262" />


---

## Requirements

- Windows 10 / 11
- [AutoHotkey v2](https://www.autohotkey.com/) — free and easy to install

---

## Installation

1. Install **AutoHotkey v2** from [autohotkey.com](https://www.autohotkey.com)
2. Download `DiscordTimer_EN.ahk` from this repository
3. Double-click the file — the app will launch

---

## Usage

- Run the script — the window appears in the top-right corner of your screen
- Open Discord (app or browser) and send a message
- After the first **Enter** the timer starts automatically
- Every new message resets the timer to zero

### Buttons

| Button | Action |
|---|---|
| Pause / Resume | Pauses or resumes the timer |
| Reset | Resets the timer to `00:00:00` |
| Clear log | Resets everything — timer, counter, log |

### Timer colors

| Color | Meaning |
|---|---|
| 🟢 Green | less than 2 minutes |
| 🟡 Yellow | 2 to 5 minutes |
| 🔴 Red | more than 5 minutes |

---

## Supported Discord platforms

| Platform | Support |
|---|---|
| Discord app | ✅ |
| Discord in Chrome | ✅ |
| Discord in Firefox | ✅ |
| Discord in Edge | ✅ |
| Discord in Opera / Brave | ✅ |

---

## Run on startup

To launch the timer automatically with Windows:

1. Press `Win + R`, type `shell:startup`
2. Copy `DiscordTimer_EN.ahk` into the folder that opens

---

## License

MIT — do whatever you want.
