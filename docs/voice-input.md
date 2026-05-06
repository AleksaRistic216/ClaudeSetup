# Voice input on Windows (whisper.cpp + ffmpeg + AutoHotkey)

> **Platform: Windows only.** Everything in this document — AutoHotkey, ffmpeg
> dshow, Core Audio COM, `cmd /c` wrappers, the WAV-header Buffer trick, the
> `CTRL_C_EVENT` / `AttachConsole` graceful stop — is Windows-specific.
>
> On **Linux**, the equivalent setup is typically a few minutes: build
> whisper.cpp, wire a desktop shortcut (GNOME / KDE / sway / i3) to a shell
> script that records with `arecord` or `parecord` and pipes into
> `whisper-cli`. No AHK, no dshow, no COM.
>
> On **macOS**, something similar using `sox` or `ffmpeg -f avfoundation` plus
> a Hammerspoon / Karabiner hotkey.
>
> `/setup` only offers the voice input step on Windows; the files in
> `machine/whisper-hotkey.ahk` and `machine/get-default-mic.ps1` are no-ops on
> other platforms.

Toggle voice input bound to **Ctrl+Alt+R**. Press once to start recording, press
again to stop — the transcription is typed at the cursor. All local, no cloud.

- **Recording**: ffmpeg dshow → raw PCM at 16kHz mono 16-bit
- **Transcription**: whisper.cpp (`base.en` model)
- **Hotkey + glue**: AutoHotkey v2 single script
- **Files**: `machine/whisper-hotkey.ahk`, `machine/get-default-mic.ps1`

`/setup` installs both files to `~/.claude/` (Windows only) and walks through
the manual steps below.

## Prerequisites

Install in this order:

### 1. CMake
```powershell
winget install Kitware.CMake
```
Restart your terminal so `cmake` lands on `PATH`.

### 2. Visual Studio Build Tools with C++ workload
```powershell
winget install Microsoft.VisualStudio.2022.BuildTools
```
After install, open **Visual Studio Installer** → Modify → **Workloads** tab →
check **"Desktop development with C++"** → Modify. This installs MSVC (`cl.exe`)
which CMake needs for native builds.

> `winget --override "--add Microsoft.VisualStudio.Workload.VCTools --passive"`
> should work in theory, but in practice the `winget install` completes before
> the workload finishes downloading, so you end up with an empty Build Tools
> install and no compiler. Use the GUI.

### 3. Build whisper.cpp
```bash
git clone https://github.com/ggml-org/whisper.cpp ~/source/whisper.cpp
cd ~/source/whisper.cpp
cmake -B build -G "Visual Studio 17 2022"
cmake --build build --config Release
bash models/download-ggml-model.sh base.en
```
The binary lands at `~/source/whisper.cpp/build/bin/Release/whisper-cli.exe`;
the model at `~/source/whisper.cpp/models/ggml-base.en.bin`. Use the generator
that matches your installed Visual Studio version (`"Visual Studio 18 2026"`,
etc.). If `cmake -B build` fails with `CMAKE_C_COMPILER not set`, the C++
workload is missing.

### 4. ffmpeg
```powershell
winget install Gyan.FFmpeg
```
The symlink at `%LOCALAPPDATA%\Microsoft\WinGet\Links\ffmpeg.exe` is
version-agnostic — the AHK script uses that, so upgrades don't break it.

### 5. AutoHotkey v2
```powershell
winget install AutoHotkey.AutoHotkey
```

## Configure the hotkey

### Set your preferred mic as Windows default

Right-click the speaker tray icon → **Sound settings** → **Input** → pick your
mic. Also click **"Test your microphone"** to confirm the bar moves — this
weeds out dead Bluetooth connections early.

### Detect the exact device name

ffmpeg's dshow backend needs the exact friendly name Windows uses. Run:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\get-default-mic.ps1"
```
Sample output: `Microphone (Trust USB microphone )`. Copy this verbatim —
including trailing spaces and weird punctuation — into the `MicName :=` line at
the top of `~/.claude/whisper-hotkey.ahk`.

### Auto-launch on login (elevated)

Use a scheduled task so the hotkey runs elevated — this lets `SendText` reach
admin terminals and other elevated windows (Windows UIPI blocks non-elevated
senders). A startup shortcut can't request elevation without a UAC prompt on
every login; a scheduled task with `RunLevel Highest` can.

```powershell
$action   = New-ScheduledTaskAction -Execute "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" `
              -Argument "`"$env:USERPROFILE\.claude\whisper-hotkey.ahk`""
$trigger  = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
              -ExecutionTimeLimit ([TimeSpan]::Zero)
Register-ScheduledTask -TaskName "WhisperHotkey" -Action $action -Trigger $trigger `
  -Principal $principal -Settings $settings -Force
```

> If you previously used a startup shortcut, remove it:
> `Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\whisper-hotkey.lnk" -ErrorAction SilentlyContinue`

### Launch now
```powershell
Start-Process "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "$env:USERPROFILE\.claude\whisper-hotkey.ahk" -Verb RunAs
```

Press **Ctrl+Alt+R**, speak, press **Ctrl+Alt+R** again. The transcription is
typed at the cursor.

> **Clipboard fallback:** The script always copies the transcription to the
> clipboard before calling `SendText`. If typing doesn't work (e.g., a stubborn
> app that blocks synthetic input), just **Ctrl+V** to paste.

## How it works

1. Ctrl+Alt+R fires; AHK launches `ffmpeg -f dshow -i "audio=<MicName>"` via a
   `cmd.exe /c` wrapper so stderr can be redirected to `C:\Temp\ffmpeg-err.log`.
2. ffmpeg records raw PCM to `C:\Temp\whisper.pcm`.
3. Ctrl+Alt+R fires again. AHK finds the real ffmpeg PID (child of cmd) and
   calls `AttachConsole` + `GenerateConsoleCtrlEvent(CTRL_C_EVENT)` on it —
   same as pressing `q` interactively. ffmpeg flushes its buffer and exits.
4. AHK wraps the PCM in a 44-byte WAV header (`NumPut` into a 44-byte Buffer).
5. `whisper-cli … --no-timestamps -otxt` runs synchronously; the resulting
   `.txt` is read, trimmed, and typed with `SendText`.

Diagnostic logs:
- `C:\Temp\whisper.log` — AHK's step-by-step trace
- `C:\Temp\ffmpeg-err.log` — ffmpeg's stderr output

## Gotchas encountered along the way

Design notes so the next iteration doesn't walk the same minefield.

### `SendText` silently fails against elevated windows (UIPI)
Windows **User Interface Privilege Isolation** blocks a non-elevated process
from sending synthetic input to an elevated one. If the AHK script runs at
normal privilege and the target window (e.g., an admin terminal) is elevated,
`SendText` does nothing — no error, no text. The fix: run the AHK script
elevated (scheduled task with `RunLevel Highest`) and always copy the
transcription to the clipboard as a fallback.

### Hotkey clashes with Xbox Game Bar
**Win+Alt+R** is Xbox Game Bar's screen-recording shortcut. Pressing it opens
the capture bar, and our hotkey never fires. Use **Ctrl+Alt+R** (or similar
non-Win combo).

### PowerShell startup is expensive
Each `powershell.exe` cold-start with `Add-Type` burns ~2–3 seconds before any
code runs. During that window the "REC" tooltip shows but ffmpeg hasn't even
launched — the user speaks, hits the key to stop, and the recording is 0.3s
long. Launching ffmpeg **directly from AHK via `Run`** sidesteps this entirely.

### PowerShell's `Start-Process -ArgumentList @(...)` splits on spaces
Passing `@('-i', 'audio=Microphone Array (Realtek(R) Audio)')` produced
`-i audio=Microphone` at the ffmpeg command line — the argument got re-split
at the first space despite being a single array element. Either pass a single
pre-quoted string, or skip `Start-Process` entirely (we did).

### MCI `waveInGetDevCaps(WAVE_MAPPER, ...)` returns "Microsoft Sound Mapper"
That's the virtual mapper, not your real device. Core Audio via
`IMMDeviceEnumerator::GetDefaultAudioEndpoint(eCapture, eConsole)` +
`PKEY_Device_FriendlyName` gives the actual name — see `get-default-mic.ps1`.

### Core Audio CoClass GUID ≠ interface GUID
`BCDE0395-E52F-467C-8E3D-C4579291692E` is the **MMDeviceEnumerator coclass**
(pass to `Type.GetTypeFromCLSID`). `A95664D2-9614-4F35-A746-DE8DB63617E6` is
the **IMMDeviceEnumerator interface** (put in `[ComImport, Guid(...)]`).
Mixing them up fails with `E_NOINTERFACE`.

### `taskkill /im ffmpeg.exe /F` truncates the PCM file to 0 bytes
ffmpeg reports "size=187KiB" in stderr but the file on disk is empty after a
force-kill. The fix is to send **CTRL_C_EVENT** via `AttachConsole` +
`GenerateConsoleCtrlEvent` — ffmpeg handles it like an interactive `q`, flushes
pending writes, and exits cleanly.

### `taskkill` without `/F` often can't reach a hidden-console ffmpeg
The graceful-close path for console apps relies on a console window to deliver
the message; when the process was launched hidden it may never arrive.
`AttachConsole` + `GenerateConsoleCtrlEvent` reaches it regardless.

### Auto-detecting the mic per recording is worse than hardcoding it
Running the Core Audio PS script before each hotkey press adds 300–500 ms of
latency for no real benefit — mics rarely change mid-session. Hardcode the
name and change it when the hardware changes. `get-default-mic.ps1` is the
one-time discovery tool; the AHK script reads a static value.

### Bluetooth mics are flaky on Windows
SCO profile switching, driver weirdness, and reconnection state can leave a
"connected" headset with no capture path. If the hotkey works intermittently
with a Bluetooth mic but perfectly with USB, that's why. A wired / USB mic
avoids a whole category of bugs.
