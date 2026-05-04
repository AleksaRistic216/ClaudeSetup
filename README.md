# ClaudeSetup

Reusable [Claude Code](https://claude.ai/code) configuration — global commands, custom agents, and project scaffolding templates. Not a software application; this repo exists to keep Claude Code setup portable and version-controlled.

## Quick Start

```
cd ClaudeSetup
/setup
```

This copies everything under `machine/` to `~/.claude/`, making commands and agents available in all projects. Re-run after pulling updates.

## What Gets Installed

| Source | Destination | Purpose |
|---|---|---|
| `machine/commands/*.md` | `~/.claude/commands/` | Global slash commands |
| `machine/agents/*.md` | `~/.claude/agents/` | Custom agents |
| `machine/CLAUDE.md` | `~/.claude/CLAUDE.md` | Global instructions |

## Commands

| Command | Description |
|---|---|
| `/commit` | Git commit with a concise message (≤50 chars, present tense, no attribution) |
| `/review-code` | Multi-pass code review with alternative implementation research |
| `/project-bundle` | Scaffold a full-stack project (.NET 9.0 backend + Next.js frontend) |

## Agents

| Agent | Model | Description |
|---|---|---|
| `code-review-analyst` | Opus | Deep multi-pass code review |
| `code-change-reviewer` | Sonnet | Review uncommitted and unpushed changes |

## Repository Structure

```
ClaudeSetup/
├── machine/                   # Mirrors ~/.claude/ — add new global config here
│   ├── CLAUDE.md              # Global instructions
│   ├── commands/              # Global slash commands
│   │   ├── commit.md
│   │   ├── review-code.md
│   │   └── project-bundle.md
│   └── agents/                # Custom agents
│       ├── code-review-analyst.md
│       └── code-change-reviewer.md
├── .claude/
│   └── skills/
│       └── setup/SKILL.md     # /setup skill (only useful inside this repo)
└── CLAUDE.md                  # Project-level instructions
```

## Docs

| Doc | Description |
|---|---|
| [`docs/stt.md`](docs/stt.md) | Speech-to-text setup (Whisper CPP, English + Serbian hotkeys) |

## Adding New Commands or Agents

1. Add the `.md` file under `machine/commands/` or `machine/agents/`
2. Run `/setup` to install it to `~/.claude/`
