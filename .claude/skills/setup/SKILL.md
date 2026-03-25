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

### Step 6: Verify installation

List the installed files and confirm success:

```bash
ls -la ~/.claude/commands/
ls -la ~/.claude/agents/
cat ~/.claude/CLAUDE.md
```

### Step 7: Report

Tell the user:
- What was installed
- Which commands are now available globally (e.g., `/commit`, `/review-code`, `/project-bundle`)
- Remind them to re-run `/setup` from this repo after pulling updates

## Important Notes

- NEVER modify `~/.claude/settings.json` or `~/.claude/settings.local.json` — those contain machine-specific permissions and should be managed manually
- If `machine/CLAUDE.md` does not exist in the repo, skip that step without error
- This skill is idempotent — safe to re-run after pulling repo updates

$ARGUMENTS
