---
description: Toggle the Claude Code experimental agent teams feature on or off in ~/.claude/settings.json.
---

# Battle Royale — Toggle Agent Teams

This command toggles the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` experimental feature in `~/.claude/settings.json`.

Agent teams let multiple Claude Code instances collaborate: one acts as team lead while others work as teammates, each with their own context window.

## Help

If `$ARGUMENTS` contains `-h` or `--help`, do NOT run the command. Instead, print the following and stop:

```
/battle-royale — Toggle Claude Code experimental agent teams feature

Options:
  -h, --help    Show this help message

Toggles CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS in ~/.claude/settings.json.
Prints the new state after toggling.
```

## Instructions

1. **Check for help flag**: If `$ARGUMENTS` contains `-h` or `--help`, print the help text above and stop.

2. **Read current settings**: Read `~/.claude/settings.json`. If the file doesn't exist or is empty, treat it as `{}`.

3. **Determine current state**: Check `settings.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`:
   - If it equals `"1"` → currently **enabled**
   - Otherwise (missing, `"0"`, or any other value) → currently **disabled**

4. **Toggle**:
   - If currently **enabled**: remove `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` from `settings.env`. If `settings.env` becomes empty after removal, remove the `env` key entirely. Also remove the top-level `teammateMode` key if present.
   - If currently **disabled**: set `settings.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` to `"1"` and set the top-level `teammateMode` to `"tmux"`.

5. **Write back**: Save the updated JSON to `~/.claude/settings.json`, preserving all other existing settings. Use 2-space indentation.

6. **Report**: Print a single confirmation line, e.g.:
   - `Agent teams enabled.` (when turning on)
   - `Agent teams disabled.` (when turning off)

$ARGUMENTS
