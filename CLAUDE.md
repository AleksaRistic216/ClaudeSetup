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
│   ├── commands/                          # Global slash commands (all projects)
│   │   ├── battle-royale.md
│   │   ├── commit.md
│   │   ├── team.md
│   │   ├── review-code.md
│   │   └── project-bundle.md
│   └── agents/                            # Custom agents (all projects)
│       ├── code-review-analyst.md         # Deep multi-pass code review (opus)
│       └── code-change-reviewer.md        # Uncommitted changes review (sonnet)
├── .claude/
│   ├── settings.local.json                # Local permission allowlist
│   └── skills/
│       └── setup/SKILL.md                 # Installs machine/ to ~/.claude/
└── docs/
    └── commands/
        └── project-bundle/
            └── docs/                      # BE docs copied into new projects by /project-bundle
```

## Usage

Run `/setup` from this repo to install all global commands and instructions to `~/.claude/`. Re-run after pulling updates.

## What gets installed

| Source                     | Destination            | Purpose                              |
|----------------------------|------------------------|--------------------------------------|
| `machine/commands/*.md`    | `~/.claude/commands/`  | Global slash commands (all projects) |
| `machine/agents/*.md`      | `~/.claude/agents/`    | Custom agents (all projects)         |
| `machine/CLAUDE.md`        | `~/.claude/CLAUDE.md`  | Global instructions (all projects)   |

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

## Conventions

- `machine/` mirrors `~/.claude/` structure — add new global commands here
- `.claude/skills/setup/` is the only project-level skill (only useful inside this repo)
- No build/test/lint commands — this is a configuration-only repo
- **Every command must support `-h` / `--help`**: Add a `## Help` section that checks `$ARGUMENTS` for the flag, prints a short description + options table, and stops without executing. See existing commands for the pattern.
