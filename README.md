# ClaudeSetup

Reusable [Claude Code](https://claude.ai/code) and [GitHub Copilot CLI](https://docs.github.com/copilot/concepts/agents/about-copilot-cli) configuration — global commands, custom agents, and project scaffolding templates. Not a software application; this repo exists to keep AI coding assistant setup portable and version-controlled.

## Quick Start

```
cd ClaudeSetup
/setup
```

This copies everything under `machine/` to `~/.claude/` and mirrors commands/agents to `~/.copilot/`, making them available in all projects for both Claude Code and GitHub Copilot CLI. Re-run after pulling updates.

## What Gets Installed

| Source | Destination | Purpose |
|---|---|---|
| `machine/commands/*.md` | `~/.claude/commands/` + `~/.copilot/commands/` | Global slash commands |
| `machine/agents/*.md` | `~/.claude/agents/` + `~/.copilot/agents/` | Custom agents |
| `machine/skills/*/` | `~/.claude/skills/` | Skills (Claude Code only — not mirrored to Copilot) |
| `machine/CLAUDE.md` | `~/.claude/CLAUDE.md` + `~/.copilot/copilot-instructions.md` | Global instructions |
| `machine/conemu/*` | *(runs in-place)* | ConEmu terminal setup (Windows) |

## Commands

| Command | Description |
|---|---|
| `/commit` | Git commit with a concise message (≤50 chars, present tense, no attribution) |
| `/review-code` | Multi-pass code review with alternative implementation research |
| `/project-bundle` | Scaffold a full-stack project (.NET 9.0 backend + Next.js frontend) |

## Skills

`machine/skills/` installs skill *directories* to `~/.claude/skills/` (Claude Code only — not
mirrored to Copilot). None ship here right now: the review panel moved to
[DXAgentEnvironment](https://github.com/AleksaRistic216/DXAgentEnvironment), whose `machine/` tree
owns everything matching `review-*`. Keeping one copy matters — two would drift, and the loser is
whichever installer ran second.

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
│   ├── agents/                # Custom agents
│   │   ├── code-review-analyst.md
│   │   └── code-change-reviewer.md
│   ├── skills/                # Skills (directories, Claude Code only)
│   └── conemu/                # ConEmu terminal setup (Windows)
│       └── setup-conemu.ps1
├── docs/
│   ├── conemu.md              # ConEmu shortcut reference
│   └── voice-input.md
├── .claude/
│   └── skills/
│       └── setup/SKILL.md     # /setup skill (only useful inside this repo)
└── CLAUDE.md                  # Project-level instructions
```

## Docs

| Doc | Description |
|---|---|
| [`docs/stt.md`](docs/stt.md) | Speech-to-text setup (Whisper CPP, English + Serbian hotkeys) |

## Adding New Commands, Agents or Skills

1. Add the `.md` file under `machine/commands/` or `machine/agents/`, or a directory containing a
   `SKILL.md` under `machine/skills/`
2. Run `/setup` to install it to `~/.claude/` (and `~/.copilot/`, for commands and agents)

Frontmatter is YAML, and an unquoted `: ` inside a `description` silently unregisters the agent or
skill — it simply does not appear in the session, with no error anywhere. Use an em dash instead,
or quote the scalar. Parse the block before committing:

```bash
python -c "import sys,yaml,re;t=open(sys.argv[1],encoding='utf-8').read();yaml.safe_load(re.match(r'^---\n(.*?)\n---',t,re.S).group(1))" machine/agents/<file>.md
```
