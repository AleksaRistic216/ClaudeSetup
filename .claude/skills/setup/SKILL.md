---
name: setup
description: Install Claude Code configuration from this repository to the local machine (~/.claude/). Sets up global commands, CLAUDE.md, and settings at the user level so they are available in all projects.
allowed-tools: Bash, Read, Write, Glob, Edit
---

# Machine-Level Claude Code Setup

This skill installs the Claude Code configuration from this repository to the local machine.

## What gets installed

Everything under the `machine/` directory in this repo is copied to `~/.claude/`, mirroring the directory structure:

| Source (repo)                   | Destination                         | Purpose                              |
|---------------------------------|-------------------------------------|--------------------------------------|
| `machine/commands/*.md`         | `~/.claude/commands/`               | Global slash commands |
| `machine/agents/*.md`           | `~/.claude/agents/`                 | Custom agents |
| `machine/CLAUDE.md`             | `~/.claude/CLAUDE.md`               | Global instructions |
| `machine/conemu/setup-conemu.ps1` | *(runs in-place)* | ConEmu terminal setup (Windows only) |
| `machine/hooks/*.sh`            | `~/.claude/hooks/`                  | PreToolUse/PostToolUse hook scripts  |
| `machine/whisper-hotkey.ahk`    | `~/.claude/whisper-hotkey.ahk`      | Voice input hotkey (Windows only)    |
| `machine/get-default-mic.ps1`   | `~/.claude/get-default-mic.ps1`     | Helper: detect default capture mic   |

## Instructions

Follow these steps in order:

### Step 0: Check prerequisites (whisper.cpp)

Detect the OS and check whether whisper.cpp is present. Use `uname -s` on Linux/macOS; on Windows the shell is typically Git Bash or WSL.

```bash
uname -s 2>/dev/null || echo "Windows"
```

Then check for the whisper-cli binary:

```bash
# Check PATH first, then the default build location
command -v whisper-cli 2>/dev/null \
  || command -v whisper-cli.exe 2>/dev/null \
  || test -f "$HOME/whisper.cpp/build/bin/whisper-cli" && echo "found" \
  || test -f "$HOME/whisper.cpp/build/bin/Release/whisper-cli.exe" && echo "found" \
  || echo "not found"
```

**If whisper-cli is found:** print "`whisper.cpp — OK`" and continue to model checks.

**If not found:** print a warning and installation instructions for the detected OS, then ask the user whether to continue setup anyway or stop to install whisper.cpp first.

#### Model checks (run only if whisper-cli was found)

Check for both STT models:

```bash
test -f "$HOME/whisper.cpp/models/ggml-small.en.bin" && echo "english model found" || echo "english model missing"
test -f "$HOME/whisper.cpp/models/ggml-large-v3.bin" && echo "serbian model found" || echo "serbian model missing"
```

Print a status line for each:
- Found: `ggml-small.en.bin — OK` / `ggml-large-v3.bin — OK`
- Missing: `ggml-small.en.bin — MISSING` / `ggml-large-v3.bin — MISSING`

For any missing model, print the download command:

```
To download the English model:
  cd ~/whisper.cpp && bash models/download-ggml-model.sh small.en

To download the Serbian (multilingual) model:
  cd ~/whisper.cpp && bash models/download-ggml-model.sh large-v3
```

Missing models are a warning only — do not block setup or ask for confirmation.

Linux instructions to show:
```
whisper.cpp not found. To install on Linux:

  git clone https://github.com/ggml-org/whisper.cpp ~/whisper.cpp
  cd ~/whisper.cpp
  cmake -B build
  cmake --build build --config Release
  bash models/download-ggml-model.sh base.en

After building, whisper-cli will be at ~/whisper.cpp/build/bin/whisper-cli
```

Windows instructions to show:
```
whisper.cpp not found. To install on Windows:

  git clone https://github.com/ggml-org/whisper.cpp %USERPROFILE%\whisper.cpp
  cd %USERPROFILE%\whisper.cpp
  cmake -B build
  cmake --build build --config Release
  bash models/download-ggml-model.sh base.en

After building, whisper-cli will be at %USERPROFILE%\whisper.cpp\build\bin\Release\whisper-cli.exe
```

Wait for user confirmation before proceeding if whisper.cpp is missing.

### Step 1: Determine the repo root

The repo root is the directory containing this skill's parent `.claude/` directory. All paths below are relative to the repo root.

### Step 2: Detect conflicts and show installation plan

1. List all files under `machine/` in the repo
2. For each file, check if the destination already exists in `~/.claude/`
3. Show the user a single summary separating new files from files that will be overwritten

Example output:
```
The following will be installed to ~/.claude/:

Commands (→ ~/.claude/commands/):
  - commit.md (NEW)
  - review-code.md (OVERRIDE — already exists)
  - project-bundle.md (NEW)

Agents (→ ~/.claude/agents/):
  - code-review-analyst.md (OVERRIDE — already exists)
  - code-change-reviewer.md (NEW)

Global instructions:
  - CLAUDE.md (OVERRIDE — already exists)

Files marked OVERRIDE will replace the existing versions.
Proceed? (y/n)
```

If there are no overrides, skip the warning — just show the list and ask to proceed.

Wait for user confirmation, then continue.

### Step 3: Install commands

```bash
mkdir -p ~/.claude/commands
cp machine/commands/*.md ~/.claude/commands/
```

### Step 4: Install agents

```bash
mkdir -p ~/.claude/agents
cp machine/agents/*.md ~/.claude/agents/
```

### Step 5: Install global CLAUDE.md

Only if `machine/CLAUDE.md` exists in the repo:

```bash
cp machine/CLAUDE.md ~/.claude/CLAUDE.md
```

### Step 6: Install hooks

Only if `machine/hooks/` exists and contains `.sh` files:

```bash
mkdir -p ~/.claude/hooks
cp machine/hooks/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh
```

Then merge hook registrations into `~/.claude/settings.json`. For each hook script in `machine/hooks/`, check if it is already registered in `settings.json`. If not, add it.

Use this Python snippet to merge without overwriting existing settings:

```bash
python3 - <<'EOF'
import json, os

settings_path = os.path.expanduser("~/.claude/settings.json")
with open(settings_path) as f:
    settings = json.load(f)

hooks = settings.setdefault("hooks", {})
pre = hooks.setdefault("PreToolUse", [])

entry = {
    "matcher": "Bash",
    "hooks": [{"type": "command", "command": "~/.claude/hooks/pre-bash-check.sh"}]
}

# Only add if not already registered
already = any(
    any(h.get("command") == "~/.claude/hooks/pre-bash-check.sh" for h in item.get("hooks", []))
    for item in pre
)
if not already:
    pre.append(entry)

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)

print("settings.json updated with hook registrations.")
EOF
```

Repeat this pattern for any additional hook scripts found in `machine/hooks/`, adjusting the matcher and command path accordingly.

### Step 7 (Windows only): Voice input hotkey

If the OS detected in Step 0 is Windows AND the files
`machine/whisper-hotkey.ahk` + `machine/get-default-mic.ps1` exist, offer to
install the voice input hotkey. Skip on non-Windows.

Ask the user: "Install/refresh the whisper.cpp voice input hotkey (Ctrl+Alt+R)?
Requires ffmpeg + AutoHotkey v2. [y/N]". Proceed only on 'y'.

#### 7a. Verify dependencies

```bash
command -v "/c/Program Files/AutoHotkey/v2/AutoHotkey64.exe" 2>/dev/null || echo "ahk-missing"
test -f "$LOCALAPPDATA/Microsoft/WinGet/Links/ffmpeg.exe" && echo "ffmpeg-ok" || echo "ffmpeg-missing"
```

If either is missing, print the matching install command and ask the user to
run it, then re-run `/setup`:

```
winget install AutoHotkey.AutoHotkey
winget install Gyan.FFmpeg
```

(whisper.cpp itself was already checked in Step 0.)

#### 7b. Copy the scripts

```bash
cp machine/whisper-hotkey.ahk ~/.claude/whisper-hotkey.ahk
cp machine/get-default-mic.ps1 ~/.claude/get-default-mic.ps1
```

#### 7c. Detect the default capture mic and substitute it into the AHK script

The AHK template ships with `MicName := "REPLACE_WITH_YOUR_MIC_NAME"`. Run
the PowerShell helper to discover the current Windows default, then `sed` it
in:

```bash
MIC=$(powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$USERPROFILE/.claude/get-default-mic.ps1" 2>/dev/null | tr -d '\r' | tail -n1)
echo "Detected default mic: $MIC"
```

If `$MIC` is empty, tell the user to:
1. Set their preferred mic as default in Windows Sound Settings (Input tab)
2. Re-run `/setup`

Otherwise, substitute the placeholder:

```bash
# Escape sed metacharacters in the mic name (might contain parens, spaces, etc.)
MIC_ESCAPED=$(printf '%s' "$MIC" | sed 's/[\/&]/\\&/g')
sed -i "s/REPLACE_WITH_YOUR_MIC_NAME/$MIC_ESCAPED/" ~/.claude/whisper-hotkey.ahk
```

Verify the line:
```bash
grep "^MicName" ~/.claude/whisper-hotkey.ahk
```

#### 7d. Create the Startup shortcut so AHK auto-launches on login

```bash
powershell.exe -NoProfile -Command '
$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut("$($ws.SpecialFolders(\"Startup\"))\whisper-hotkey.lnk")
$sc.TargetPath = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
$sc.Arguments  = "`"$env:USERPROFILE\.claude\whisper-hotkey.ahk`""
$sc.Save()
'
```

#### 7e. Kill any old AHK instance and launch the new one

```bash
taskkill //IM AutoHotkey64.exe //F 2>/dev/null
powershell.exe -NoProfile -Command 'Start-Process -FilePath "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" -ArgumentList ($env:USERPROFILE + "\.claude\whisper-hotkey.ahk")'
```

Tell the user: "Ctrl+Alt+R to start recording, press again to stop. If you
change mics, edit `MicName :=` in `~/.claude/whisper-hotkey.ahk` and re-run
`/setup` (or restart AHK). See `docs/voice-input.md` for the full rationale."

### Step 8 (Windows only): ConEmu terminal setup

If the OS is Windows, configure ConEmu as the terminal emulator with custom shortcuts and display settings.

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$REPO_ROOT/machine/conemu/setup-conemu.ps1"
```

This script will:
1. Install ConEmu via winget if not already present
2. Locate ConEmu.xml and patch it with custom settings:
   - Font: JetBrains Mono
   - Zoom: Ctrl+Shift+= (in), Ctrl+- (out)
   - Split: Ctrl+T (horizontal), Ctrl+Alt+T (vertical)
   - Close panel: Ctrl+W
   - Resize panels: Alt+J/K/L/; (left/up/right/down)
   - Navigate panels: Ctrl+Alt+PgUp/PgDn/Home/End (up/down/left/right)
   - Inactive panel fade for visual focus indication

If ConEmu is not installed and winget is unavailable, print a warning and continue.
See `docs/conemu.md` for full shortcut reference.

### Step 9: Verify installation

List the installed files and confirm success:

```bash
ls -la ~/.claude/commands/
ls -la ~/.claude/agents/
ls -la ~/.claude/hooks/
cat ~/.claude/CLAUDE.md
```

### Step 10: Report

Tell the user:
- What was installed
- Which commands are now available globally (e.g., `/commit`, `/review-code`, `/project-bundle`)
- Which hooks are now active
- On Windows: whether the voice input hotkey (Ctrl+Alt+R) was set up
- Remind them to re-run `/setup` from this repo after pulling updates

## Important Notes

- `settings.json` hooks section is merged (existing keys are preserved) — only hook entries from this repo are added
- NEVER overwrite other keys in `~/.claude/settings.json` or `~/.claude/settings.local.json`
- If `machine/CLAUDE.md` does not exist in the repo, skip that step without error
- If `machine/hooks/` does not exist or is empty, skip hooks steps without error
- This skill is idempotent — safe to re-run after pulling repo updates

$ARGUMENTS
