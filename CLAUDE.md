# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains **Claude Code configuration and custom skills**. It is not a software application — it houses reusable Claude Code skills, settings, and project scaffolding templates.

## Repository Structure

```
ClaudeSetup/
├── CLAUDE.md                              # This file
├── .gitignore                             # Ignores .idea/
├── machine/                               # Files installed to ~/.claude/ via /setup
│   ├── CLAUDE.md                          # Global instructions (all projects)
│   ├── whisper-hotkey.ahk                 # Windows voice input hotkey (Ctrl+Alt+R)
│   ├── get-default-mic.ps1                # Helper: prints Windows default mic name
│   ├── commands/                          # Global slash commands (all projects)
│   │   ├── battle-royale.md
│   │   ├── commit.md
│   │   ├── team.md
│   │   ├── review-code.md
│   │   └── project-bundle.md
│   ├── agents/                            # Custom agents (all projects)
│   │   ├── code-review-analyst.md         # Deep multi-pass code review (opus)
│   │   └── code-change-reviewer.md        # Uncommitted changes review (sonnet)
│   └── hooks/                             # PreToolUse/PostToolUse hook scripts
│       └── pre-bash-check.sh
├── .claude/
│   ├── settings.local.json                # Local permission allowlist
│   └── skills/
│       └── setup/SKILL.md                 # Installs machine/ to ~/.claude/
└── docs/
    ├── voice-input.md                     # Windows whisper hotkey setup guide
    └── commands/
        └── project-bundle/
            └── docs/                      # BE docs copied into new projects by /project-bundle
```

## Usage

Run `/setup` from this repo to install all global commands and instructions to `~/.claude/`. Re-run after pulling updates.

## What gets installed

| Source                         | Destination                        | Purpose                              |
|--------------------------------|------------------------------------|--------------------------------------|
| `machine/commands/*.md`        | `~/.claude/commands/`              | Global slash commands (all projects) |
| `machine/agents/*.md`          | `~/.claude/agents/`                | Custom agents (all projects)         |
| `machine/hooks/*.sh`           | `~/.claude/hooks/`                 | PreToolUse/PostToolUse hook scripts  |
| `machine/CLAUDE.md`            | `~/.claude/CLAUDE.md`              | Global instructions (all projects)   |
| `machine/whisper-hotkey.ahk`   | `~/.claude/whisper-hotkey.ahk`     | Voice input hotkey (Windows)         |
| `machine/get-default-mic.ps1`  | `~/.claude/get-default-mic.ps1`    | Helper: detect default capture mic   |

## Global Commands

### `/battle-royale`
Toggles the experimental Claude Code agent teams feature (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`) in `~/.claude/settings.json`. Enables with `teammateMode: tmux` on Linux/macOS or `teammateMode: in-process` on Windows; disables by removing the setting.

### `/team {task}`
Executes a task in agent team mode. You act as team lead; Claude spawns teammate agents to work in parallel on independent sub-tasks, then synthesizes results.
- `-l N` / `--limit N`: cap teammates at N

### `/commit`
Creates git commits with concise messages (≤50 chars, present tense, no Claude attribution).

### `/review-code`
Thorough code review with multiple evaluation passes and alternative implementation research.

### `/project-bundle`
Scaffolds a full-stack project bundle:
- **Backend**: .NET 9.0 layered architecture (API, Contracts, Domain, Repository, Client, DbMigrations, Tests) using LSCore packages
- **Frontend**: Next.js 13+ with React 18, JavaScript (JSX), MUI, Redux, Zustand
- Flags: `-be`/`--back-end` (backend only), `-fe`/`--front-end` (frontend only), omit for both

## Voice input on Windows

`Ctrl+Alt+R` toggles local voice-to-text via whisper.cpp + ffmpeg + AutoHotkey.
The full walkthrough (prereq installs, compiler workload, mic detection, gotchas
encountered along the way) lives in [docs/voice-input.md](docs/voice-input.md).
`/setup` copies the AHK/PS1 files to `~/.claude/` and walks through the one-time
mic configuration.

**Windows-only.** Linux and macOS need a different approach (shell script +
`arecord`/`parecord` or `ffmpeg -f avfoundation` wired to a DE hotkey). The
voice-input step in `/setup` is gated on OS detection and is skipped on
Linux/macOS.

## Conventions

- `machine/` mirrors `~/.claude/` structure — add new global commands here
- `.claude/skills/setup/` is the only project-level skill (only useful inside this repo)
- No build/test/lint commands — this is a configuration-only repo
- **Every command must support `-h` / `--help`**: Add a `## Help` section that checks `$ARGUMENTS` for the flag, prints a short description + options table, and stops without executing. See existing commands for the pattern.
