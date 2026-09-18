---
name: uninstall
description: Remove configuration this repository installed to the local machine (~/.claude/ and ~/.copilot/). The inverse of /setup — deletes only files this repo owns, unregisters its hooks, and tears down the Windows voice-input hotkey.
allowed-tools: Bash, Read, Write, Glob, Edit
---

# Machine-Level Claude Code Uninstall

This skill removes the configuration that `/setup` installed from this repository.

**It only removes files this repo owns.** The inventory is built by walking `machine/` in the
repo and mapping each file to its destination. Anything in `~/.claude/` or `~/.copilot/` that
does not correspond to a file in `machine/` is left untouched.

## What gets removed

| Source (repo)                     | Removed from                                                  |
|-----------------------------------|---------------------------------------------------------------|
| `machine/commands/*.md`           | `~/.claude/commands/`, `~/.copilot/commands/`                 |
| `machine/agents/*.md`             | `~/.claude/agents/`, `~/.copilot/agents/`                     |
| `machine/skills/*/`               | `~/.claude/skills/` (Claude Code only)                        |
| `machine/CLAUDE.md`               | `~/.claude/CLAUDE.md`, `~/.copilot/copilot-instructions.md`   |
| `machine/hooks/*.sh`              | `~/.claude/hooks/` + their registrations in `settings.json`   |
| `machine/whisper-hotkey.ahk`      | `~/.claude/`, plus the Startup shortcut and running process   |
| `machine/get-default-mic.ps1`     | `~/.claude/`                                                  |

## What is NOT removed

State this in the final report so the user is not surprised:

- **ConEmu settings** — `setup-conemu.ps1` patches `ConEmu.xml` in place with no backup, so the
  keybindings cannot be reverted automatically. Point the user at ConEmu → Settings if they want
  the defaults back.
- **Installed applications** — ConEmu, AutoHotkey, ffmpeg, whisper.cpp and its models stay. Print
  the `winget uninstall` lines only if the user asks.
- **Other keys in `~/.claude/settings.json`** — only this repo's hook entries are unregistered.
- **`~/.claude/settings.local.json`**, session data, history, plugins — never touched.
- **This repository** — uninstall affects the machine, not the working copy.

## Help

If `$ARGUMENTS` contains `-h` or `--help`, print the following and stop without executing:

```
/uninstall — remove configuration this repo installed to ~/.claude/ and ~/.copilot/

Options:
  -h, --help       Show this help and exit
      --dry-run    Show the removal plan and stop; change nothing
      --claude     Only remove from ~/.claude/ (leave the Copilot mirror)
      --copilot    Only remove from ~/.copilot/ (leave Claude Code)
      --force      Also remove files that differ from the repo version
      --no-backup  Skip the backup copy taken before removal

Default: remove from both ~/.claude/ and ~/.copilot/, back up first, and keep
any file whose content differs from this repo's version (locally edited).
```

## Instructions

Follow these steps in order.

### Step 1: Determine the repo root

The repo root is the directory containing this skill's parent `.claude/` directory. All repo paths
below are relative to it. Verify `machine/` exists there — if it does not, stop and say so, because
without it there is no inventory and nothing may be deleted by guesswork.

### Step 2: Build the removal inventory

For every file under `machine/`, resolve its destination(s) and classify it:

- **MISSING** — destination does not exist; nothing to do
- **MATCHES** — destination is byte-identical to the repo version; safe to remove
- **MODIFIED** — destination exists but differs from the repo version; **kept by default**, removed
  only with `--force`

```bash
cd "$REPO_ROOT"

classify() {  # $1 = repo file, $2 = destination
  if [ ! -e "$2" ]; then echo "MISSING"
  elif cmp -s "$1" "$2"; then echo "MATCHES"
  else echo "MODIFIED"; fi
}

for f in machine/commands/*.md; do
  n=$(basename "$f")
  echo "commands/$n -> ~/.claude/commands/$n [$(classify "$f" "$HOME/.claude/commands/$n")]"
done

for f in machine/agents/*.md; do
  n=$(basename "$f")
  echo "agents/$n -> ~/.claude/agents/$n [$(classify "$f" "$HOME/.claude/agents/$n")]"
done

for d in machine/skills/*/; do
  n=$(basename "$d")
  if [ -d "$HOME/.claude/skills/$n" ]; then
    if diff -rq "$d" "$HOME/.claude/skills/$n" >/dev/null 2>&1; then s=MATCHES; else s=MODIFIED; fi
  else s=MISSING; fi
  echo "skills/$n/ -> ~/.claude/skills/$n/ [$s]"
done

for f in machine/hooks/*.sh; do
  n=$(basename "$f")
  echo "hooks/$n -> ~/.claude/hooks/$n [$(classify "$f" "$HOME/.claude/hooks/$n")]"
done

[ -f machine/CLAUDE.md ] && echo "CLAUDE.md -> ~/.claude/CLAUDE.md [$(classify machine/CLAUDE.md "$HOME/.claude/CLAUDE.md")]"
```

Do the same for the Copilot mirror (`~/.copilot/commands/`, `~/.copilot/agents/`,
`~/.copilot/copilot-instructions.md`) unless `--claude` was passed, and skip the `~/.claude/`
side entirely when `--copilot` was passed.

The whisper files are a special case — compare `~/.claude/whisper-hotkey.ahk` against the repo
template ignoring the `MicName :=` line, since `/setup` substitutes the real mic name there:

```bash
diff <(sed 's/^MicName[[:space:]]*:=.*/MicName := PLACEHOLDER/' machine/whisper-hotkey.ahk) \
     <(sed 's/^MicName[[:space:]]*:=.*/MicName := PLACEHOLDER/' "$HOME/.claude/whisper-hotkey.ahk") >/dev/null 2>&1 \
  && echo "whisper-hotkey.ahk [MATCHES]" || echo "whisper-hotkey.ahk [MODIFIED]"
```

Also check for the hook registrations and the Startup shortcut:

```bash
grep -o '\.claude/hooks/[a-z-]*\.sh' "$HOME/.claude/settings.json" 2>/dev/null | sort -u
powershell.exe -NoProfile -Command '
  $p = Join-Path ([Environment]::GetFolderPath("Startup")) "whisper-hotkey.lnk"
  if (Test-Path $p) { "startup shortcut: present" } else { "startup shortcut: absent" }'
```

### Step 3: Show the plan and confirm

Show a single summary grouped the same way `/setup` groups its install plan, with a count line and
an explicit list of anything being kept:

```
The following will be removed from ~/.claude/:

Commands (~/.claude/commands/):
  - commit.md
  - review-code.md
  - team.md
  - project-bundle.md
  - battle-royale.md

Agents (~/.claude/agents/):
  - 31 files (code-review-analyst.md, code-change-reviewer.md, review-*.md)

Skills (~/.claude/skills/):
  - review-panel/

Hooks:
  - ~/.claude/hooks/pre-bash-check.sh
  - PreToolUse registration in ~/.claude/settings.json

Global instructions:
  - ~/.claude/CLAUDE.md

Voice input (Windows):
  - ~/.claude/whisper-hotkey.ahk, ~/.claude/get-default-mic.ps1
  - Startup shortcut whisper-hotkey.lnk
  - running AutoHotkey64.exe instance

Copilot mirror (~/.copilot/):
  - commands/ (5 files), agents/ (31 files), copilot-instructions.md

KEPT — differs from the repo version (pass --force to remove):
  - ~/.claude/agents/code-review-analyst.md

Backup: ~/.claude-uninstall-backup-20260918-142300/
NOT removed: ConEmu.xml keybindings, installed apps, other settings.json keys.

Proceed? (y/n)
```

**Wait for an explicit `y`.** On `--dry-run`, print the plan and stop here.

### Step 4: Back up before removing

Unless `--no-backup` was passed, copy the affected trees before touching them. This is cheap and
makes the whole operation reversible by hand:

```bash
BACKUP="$HOME/.claude-uninstall-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
for p in "$HOME/.claude/commands" "$HOME/.claude/agents" "$HOME/.claude/skills" \
         "$HOME/.claude/hooks" "$HOME/.claude/CLAUDE.md" "$HOME/.claude/settings.json" \
         "$HOME/.claude/whisper-hotkey.ahk" "$HOME/.claude/get-default-mic.ps1" \
         "$HOME/.copilot"; do
  [ -e "$p" ] && cp -r "$p" "$BACKUP/" 2>/dev/null
done
echo "Backed up to $BACKUP"
```

Report the backup path in Step 10 — the user needs it to undo this. Note `~/.copilot` lands in
the backup as `.copilot`, so use `ls -a` to confirm it is there.

### Step 5: Remove commands, agents, skills and CLAUDE.md

Delete only the paths classified MATCHES in Step 2 (plus MODIFIED ones when `--force` was passed).
Never `rm -rf` a whole destination directory — other tools and hand-written files live there.

```bash
for f in machine/commands/*.md; do rm -f "$HOME/.claude/commands/$(basename "$f")"; done
for f in machine/agents/*.md;   do rm -f "$HOME/.claude/agents/$(basename "$f")"; done
for d in machine/skills/*/;     do rm -rf "$HOME/.claude/skills/$(basename "$d")"; done
rm -f "$HOME/.claude/CLAUDE.md"
```

Filter each loop against the Step 2 classification — skip files marked MODIFIED or MISSING.

### Step 6: Remove hooks and unregister them

```bash
for f in machine/hooks/*.sh; do rm -f "$HOME/.claude/hooks/$(basename "$f")"; done
```

Then strip the registrations from `~/.claude/settings.json`, leaving every other key alone.
Run this from the repo root — it globs `machine/hooks/*.sh` to learn which commands are ours.
On Windows `python3` is often a Microsoft Store alias stub that resolves on `command -v` but
fails on execution, so pick an interpreter that actually runs:

```bash
PY=$(command -v python3 >/dev/null 2>&1 && python3 -c "1" >/dev/null 2>&1 && echo python3 || echo python)
$PY - <<'EOF'
import json, os, glob

settings_path = os.path.expanduser("~/.claude/settings.json")
if not os.path.exists(settings_path):
    raise SystemExit("no settings.json — nothing to unregister")

with open(settings_path) as f:
    settings = json.load(f)

# Hook scripts this repo owns, matched by basename
owned = {os.path.basename(p) for p in glob.glob("machine/hooks/*.sh")}

def is_ours(hook):
    cmd = hook.get("command", "")
    return any(cmd.endswith(name) and ".claude/hooks/" in cmd for name in owned)

hooks = settings.get("hooks", {})
removed = 0
for event, entries in list(hooks.items()):
    kept_entries = []
    for entry in entries:
        inner = [h for h in entry.get("hooks", []) if not is_ours(h)]
        removed += len(entry.get("hooks", [])) - len(inner)
        if inner:
            entry["hooks"] = inner
            kept_entries.append(entry)
    if kept_entries:
        hooks[event] = kept_entries
    else:
        del hooks[event]
if not hooks:
    settings.pop("hooks", None)
else:
    settings["hooks"] = hooks

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)

print(f"Unregistered {removed} hook(s) from settings.json")
EOF
```

An entry is dropped only when every hook inside it belonged to this repo; a matcher group the user
added other hooks to keeps those hooks and stays.

### Step 7 (Windows only): Tear down the voice input hotkey

Skip on Linux/macOS. Ask first — the hotkey is the one piece a user may want to keep:

"Also remove the voice input hotkey (Ctrl+Alt+R): scripts, Startup shortcut, and the running
AutoHotkey process? [y/N]"

Per the global instruction on stopping processes, kill only the AutoHotkey instance running this
script — do not touch other AutoHotkey scripts or unrelated apps.

**Run this step through the PowerShell tool, not `powershell.exe` from bash.** The WMI filter needs
single quotes inside the command, and passing that through a bash-quoted `-Command` mangles them
into `''AutoHotkey64.exe''`, which fails with `Invalid query`.

Check what is running first:

```powershell
Get-CimInstance Win32_Process -Filter "Name = 'AutoHotkey64.exe'" |
  ForEach-Object { "pid $($_.ProcessId): $($_.CommandLine)" }
```

Then kill only the PIDs whose command line references `whisper-hotkey.ahk`, remove the Startup
shortcut, and delete the scripts:

```powershell
Get-CimInstance Win32_Process -Filter "Name = 'AutoHotkey64.exe'" |
  Where-Object { $_.CommandLine -like "*whisper-hotkey.ahk*" } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force; "Stopped PID $($_.ProcessId)" }

$p = Join-Path ([Environment]::GetFolderPath("Startup")) "whisper-hotkey.lnk"
if (Test-Path $p) { Remove-Item $p -Force; "Removed $p" } else { "No Startup shortcut found" }

foreach ($f in @("$env:USERPROFILE\.claude\whisper-hotkey.ahk", "$env:USERPROFILE\.claude\get-default-mic.ps1")) {
  if (Test-Path $f) { Remove-Item $f -Force; "Removed $f" } else { "Absent: $f" }
}
```

whisper.cpp, its models, ffmpeg and AutoHotkey itself stay installed — say so.

### Step 8: Remove the Copilot mirror

Skip when `--claude` was passed. Same rule: only files this repo owns.

```bash
for f in machine/commands/*.md; do rm -f "$HOME/.copilot/commands/$(basename "$f")"; done
for f in machine/agents/*.md;   do rm -f "$HOME/.copilot/agents/$(basename "$f")"; done
rm -f "$HOME/.copilot/copilot-instructions.md"
```

Skills were never mirrored to `~/.copilot/`, so there is nothing to remove there.

### Step 9: Prune directories this repo created, only if empty

```bash
for d in "$HOME/.claude/commands" "$HOME/.claude/agents" "$HOME/.claude/skills" \
         "$HOME/.claude/hooks" "$HOME/.copilot/commands" "$HOME/.copilot/agents"; do
  rmdir "$d" 2>/dev/null && echo "Removed empty $d"
done
```

`rmdir` without `-r` fails harmlessly when anything remains, which is the behaviour we want.

### Step 10: Verify and report

```bash
ls -la ~/.claude/commands/ ~/.claude/agents/ ~/.claude/hooks/ 2>/dev/null
ls -d ~/.claude/skills/*/ 2>/dev/null
test -f ~/.claude/CLAUDE.md && echo "CLAUDE.md STILL PRESENT" || echo "CLAUDE.md removed"
grep -c 'claude/hooks' ~/.claude/settings.json 2>/dev/null || echo "no repo hooks in settings.json"
ls -la ~/.copilot/ 2>/dev/null
```

Then tell the user:

- What was removed, per destination
- Anything **kept** because it was locally modified, and that `--force` would remove it
- Where the backup lives, and that restoring is `cp -r <backup>/<item> ~/.claude/`
- That ConEmu keybindings, installed apps (ConEmu, AutoHotkey, ffmpeg, whisper.cpp + models) and
  all other `settings.json` keys were left alone
- That `/setup` from this repo reinstalls everything

## Important Notes

- **Never delete a destination directory wholesale** — `~/.claude/` holds sessions, history,
  plugins and user files that this repo did not install
- Only this repo's hook entries are unregistered; every other key in `settings.json` is preserved
- `settings.local.json` is never touched
- Locally modified files are kept unless `--force` is passed — that asymmetry with `/setup`
  (which overwrites) is deliberate: overwriting is recoverable from git, deleting is not
- Missing files, an absent `~/.copilot/`, or an already-clean machine are not errors — report and
  continue
- This skill is idempotent — safe to re-run

$ARGUMENTS
