#Requires AutoHotkey v2.0

; ============================================================================
; Whisper.cpp voice input toggle hotkey (Windows)
; Ctrl+Alt+R to start recording, press again to stop & type the transcription.
;
; Required dependencies (installed separately — see docs/voice-input.md):
;   - whisper.cpp built at ~/source/whisper.cpp with model ggml-base.en.bin
;   - ffmpeg on PATH (via winget install Gyan.FFmpeg)
;   - AutoHotkey v2
;
; Edit MicName below so it matches the exact device name Windows reports for
; your preferred microphone. Run get-default-mic.ps1 to print that name.
; ============================================================================

MicName      := "REPLACE_WITH_YOUR_MIC_NAME"   ; exact Windows device name
FfmpegPath   := EnvGet("LOCALAPPDATA") "\Microsoft\WinGet\Links\ffmpeg.exe"
WhisperCli   := EnvGet("USERPROFILE")  "\source\whisper.cpp\build\bin\Release\whisper-cli.exe"
WhisperModel := EnvGet("USERPROFILE")  "\source\whisper.cpp\models\ggml-base.en.bin"
PcmFile      := "C:\Temp\whisper.pcm"
WavFile      := "C:\Temp\whisper.wav"
OutBase      := "C:\Temp\whisper_out"
LogFile      := "C:\Temp\whisper.log"
FfmpegErrLog := "C:\Temp\ffmpeg-err.log"

recording := false
ffmpegPID := 0
startTick := 0

if !DirExist("C:\Temp")
    DirCreate "C:\Temp"

Log(msg) {
    global LogFile
    FileAppend FormatTime(, "HH:mm:ss.") A_MSec " " msg "`n", LogFile
}

Flash(msg) {
    ToolTip msg
    SetTimer () => ToolTip(), -2000
}

; Send Ctrl+C to a process by attaching to its console. ffmpeg handles this
; as a graceful stop — it flushes buffers and closes the output file. Without
; this, force-killing ffmpeg leaves the PCM file at 0 bytes.
SendCtrlC(pid) {
    DllCall("FreeConsole")
    if !DllCall("AttachConsole", "UInt", pid)
        return false
    DllCall("SetConsoleCtrlHandler", "Ptr", 0, "Int", 1)
    DllCall("GenerateConsoleCtrlEvent", "UInt", 0, "UInt", 0)   ; CTRL_C_EVENT
    Sleep 100
    DllCall("FreeConsole")
    DllCall("SetConsoleCtrlHandler", "Ptr", 0, "Int", 0)
    return true
}

^!r:: {
    global recording, ffmpegPID, startTick, FfmpegPath, MicName, FfmpegErrLog, PcmFile, WavFile, OutBase, WhisperCli, WhisperModel

    if !recording {
        Log("=== START ===")
        Log("mic: " MicName)
        if FileExist(PcmFile)
            FileDelete PcmFile
        if FileExist(FfmpegErrLog)
            FileDelete FfmpegErrLog
        ; cmd.exe wrapper gives us stderr redirection; the outer quotes are
        ; stripped by cmd's /c quoting rules so the inner quoting survives.
        cmd := 'cmd.exe /c ""' FfmpegPath '" -hide_banner -f dshow -audio_buffer_size 50 -i "audio=' MicName '"'
             . ' -ar 16000 -ac 1 -f s16le -y "' PcmFile '" 2> "' FfmpegErrLog '""'
        Log("cmd: " cmd)
        try {
            Run cmd, , "Hide", &pid
            ffmpegPID := pid
            Log("cmd.exe PID=" pid)
        } catch as e {
            Log("Run threw: " e.Message)
            Flash("✗ Run failed: " e.Message)
            return
        }
        Sleep 100
        startTick := A_TickCount
        recording := true
        ToolTip "● REC — Ctrl+Alt+R to stop"
        return
    }

    elapsed := A_TickCount - startTick
    Log("=== STOP (elapsed=" elapsed "ms) ===")
    if elapsed < 500
        Sleep 500 - elapsed                                     ; guarantee ≥0.5s
    recording := false
    ToolTip "◌ Transcribing..."

    realFfmpegPid := ProcessExist("ffmpeg.exe")
    Log("ffmpeg real PID=" realFfmpegPid)
    if realFfmpegPid {
        SendCtrlC(realFfmpegPid)
        deadline := A_TickCount + 5000
        while ProcessExist(realFfmpegPid) && A_TickCount < deadline
            Sleep 50
        if ProcessExist(realFfmpegPid) {
            Log("Ctrl+C didn't work, force killing")
            Run "taskkill /PID " realFfmpegPid " /F", , "Hide"
            Sleep 200
        }
    }
    try ProcessClose(ffmpegPID)                                 ; cmd.exe wrapper
    ffmpegPID := 0
    Sleep 200

    ffmpegErr := FileExist(FfmpegErrLog) ? FileRead(FfmpegErrLog) : "(no stderr log)"
    Log("ffmpeg stderr: " ffmpegErr)

    if !FileExist(PcmFile) {
        Log("PCM missing")
        Flash("✗ No PCM — ffmpeg: " SubStr(ffmpegErr, 1, 200))
        return
    }
    pcmSize := FileGetSize(PcmFile)
    Log("PCM size=" pcmSize " bytes")
    if pcmSize < 1000 {
        Flash("✗ Too short (" pcmSize " B). ffmpeg: " SubStr(ffmpegErr, 1, 200))
        return
    }

    if !WrapPcmToWav(PcmFile, WavFile) {
        Flash("✗ WAV wrap failed")
        return
    }
    FileDelete PcmFile

    txtFile := OutBase ".txt"
    if FileExist(txtFile)
        FileDelete txtFile

    RunWait '"' WhisperCli '" -m "' WhisperModel '" -f "' WavFile '"'
          . ' --no-timestamps -otxt -of "' OutBase '"', , "Hide"

    if !FileExist(txtFile) {
        Log("whisper produced no output")
        Flash("✗ Whisper failed")
        return
    }
    text := Trim(FileRead(txtFile), " `t`r`n")
    FileDelete txtFile
    Log("transcription: " text)
    ToolTip
    if text = "" || text = "[BLANK_AUDIO]" {
        Flash("⚠ No speech detected")
        return
    }
    ; Always copy to clipboard as fallback — SendText silently fails when the
    ; target window is elevated and this script is not (Windows UIPI).
    A_Clipboard := text
    Log("clipboard set, calling SendText")
    SendText text
    Flash("✓ " SubStr(text, 1, 40) (StrLen(text) > 40 ? "…" : "") " 📋")
}

; We record raw PCM so force-termination can't corrupt a WAV header. This
; helper wraps the captured PCM in a minimal WAV header (16kHz mono 16-bit).
WrapPcmToWav(pcmFile, wavFile) {
    if !FileExist(pcmFile)
        return false
    pcmSize := FileGetSize(pcmFile)
    if pcmSize < 100
        return false

    pcmBuf := FileRead(pcmFile, "RAW")

    header := Buffer(44)
    NumPut("UInt",   0x46464952, header,  0)                    ; "RIFF"
    NumPut("UInt",   pcmSize + 36, header, 4)
    NumPut("UInt",   0x45564157, header,  8)                    ; "WAVE"
    NumPut("UInt",   0x20746D66, header, 12)                    ; "fmt "
    NumPut("UInt",   16,          header, 16)
    NumPut("UShort", 1,           header, 20)                   ; PCM format
    NumPut("UShort", 1,           header, 22)                   ; mono
    NumPut("UInt",   16000,       header, 24)                   ; sample rate
    NumPut("UInt",   32000,       header, 28)                   ; byte rate
    NumPut("UShort", 2,           header, 32)                   ; block align
    NumPut("UShort", 16,          header, 34)                   ; bits per sample
    NumPut("UInt",   0x61746164, header, 36)                    ; "data"
    NumPut("UInt",   pcmSize,    header, 40)

    f := FileOpen(wavFile, "w")
    if !IsObject(f)
        return false
    f.RawWrite(header, 44)
    f.RawWrite(pcmBuf, pcmSize)
    f.Close()
    return true
}
