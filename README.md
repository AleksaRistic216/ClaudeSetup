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

| Skill | Description |
|---|---|
| `/review-panel` | Reviews everything changed but not pushed, with thirty independent reviewers plus a critic |

### The review panel

`/review-panel` pins the changeset once — unpushed commits, staged, unstaged and untracked, all
diffed against a single base sha — then fans out one subagent per lens, each in its own context and
each forbidden from reviewing the others' territory. A second wave points a critic at *their
reports* rather than at the code. The session consolidates into one ranked table.

Two things make it worth the fan-out. A narrow lens finds what a general reviewer skims past, and
**two lenses landing on the same line for different reasons is real corroboration** — which one
reviewer's confidence never is. The design follows three findings from the code review literature:
most defects a review turns up do not affect visible functionality (so most lenses are not bug
hunts), the reviewer's largest unmet need is understanding the change rather than spotting faults
(`review-comprehension`), and relative code churn predicts defects better than almost anything
else (`review-history` reads `git log`, not the diff).

| Group | Lenses |
|---|---|
| Defects & runtime | `correctness` `concurrency` `security` `performance` `memory-lifetime` `error-handling` `ai-authored` |
| Design & judgement | `architecture` `alternatives` `simplicity` `maintainability` `api-ergonomics` |
| The change itself | `comprehension` `completeness` `history` `requirements` `verification` `regression-risk` |
| What ships | `compatibility` `data` `operability` `config-defaults` `docs` `logging-telemetry` |
| Platform & repo | `platform-behavior` `cross-target` `build-packaging` `generated-artifacts` `standards-compliance` `dependency` |
| Second wave | `panel-critic` — rejects false positives, duplicates and taste presented as fact |

All agent files are `machine/agents/review-*.md` and each is usable on its own.

The roster is deliberately fixed rather than selected per diff: a lens with nothing to say costs
one line, and a lens quietly skipped is a coverage gap nobody sees. Most self-limit and exit in a
line when the changeset does not reach them. Past ~25 files or 2000 lines the skill asks before
spending the full panel, and the developer can name a subset — a subset they chose is not a
coverage gap, a subset the model chose silently is.

## Agents

| Agent | Model | Description |
|---|---|---|
| `code-review-analyst` | Opus | Deep multi-pass code review |
| `code-change-reviewer` | Sonnet | Review uncommitted and unpushed changes |
| `review-*` (31) | inherit | The `/review-panel` lenses — see above |

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
│   │   ├── code-change-reviewer.md
│   │   └── review-*.md        # 31 review panel lenses + the critic
│   ├── skills/                # Skills (directories, Claude Code only)
│   │   └── review-panel/
│   │       ├── SKILL.md
│   │       └── scripts/review-scope.sh
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
