---
name: setup
description: Install Claude Code configuration from this repository to the local machine (~/.claude/). Sets up global commands, CLAUDE.md, and settings at the user level so they are available in all projects.
allowed-tools: Bash, Read, Write, Glob, Edit
---

# Machine-Level Claude Code Setup

This skill installs the Claude Code configuration from this repository to the local machine.

## What gets installed

Everything under the `machine/` directory in this repo is copied to `~/.claude/`, mirroring the directory structure:

| Source (repo)              | Destination              | Purpose                              |
|----------------------------|--------------------------|--------------------------------------|
| `machine/commands/*.md`    | `~/.claude/commands/`    | Global slash commands (all projects) |
| `machine/agents/*.md`      | `~/.claude/agents/`      | Custom agents (all projects)         |
| `machine/CLAUDE.md`        | `~/.claude/CLAUDE.md`    | Global instructions (all projects)   |
| `machine/hooks/*.sh`       | `~/.claude/hooks/`       | PreToolUse/PostToolUse hook scripts  |

## Instructions

Follow these steps in order:

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

### Step 7: Verify installation

List the installed files and confirm success:

```bash
ls -la ~/.claude/commands/
ls -la ~/.claude/agents/
ls -la ~/.claude/hooks/
cat ~/.claude/CLAUDE.md
```

### Step 8: Report

Tell the user:
- What was installed
- Which commands are now available globally (e.g., `/commit`, `/review-code`, `/project-bundle`)
- Which hooks are now active
- Remind them to re-run `/setup` from this repo after pulling updates

## Important Notes

- `settings.json` hooks section is merged (existing keys are preserved) — only hook entries from this repo are added
- NEVER overwrite other keys in `~/.claude/settings.json` or `~/.claude/settings.local.json`
- If `machine/CLAUDE.md` does not exist in the repo, skip that step without error
- If `machine/hooks/` does not exist or is empty, skip hooks steps without error
- This skill is idempotent — safe to re-run after pulling repo updates

$ARGUMENTS
