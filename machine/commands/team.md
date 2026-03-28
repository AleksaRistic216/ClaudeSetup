---
description: Execute a task using Claude Code agent team mode. Spawns teammates to work in parallel. Use when the user prefixes a request with /team to indicate they want multi-agent collaboration.
---

# Team — Execute Task with Agent Team

This command executes the given task in agent team mode: you act as **team lead** and delegate work to **teammate agents** running in parallel.

## Help

If `$ARGUMENTS` starts with `-h` or `--help`, do NOT run the command. Instead, print the following and stop:

```
/team {task} — Execute a task using Claude Code agent team mode

Usage:
  /team {task}
  /team -l {number} {task}

Options:
  -l, --limit {number}   Maximum number of teammates to spawn
  -h, --help             Show this help message

Examples:
  /team refactor the auth module and add tests
  /team -l 3 review all open PRs and summarize findings
```

## Instructions

### Step 1 — Parse arguments

From `$ARGUMENTS`:

1. If it starts with `-h` or `--help`: show the help text above and stop.
2. If it starts with `-l {N}` or `--limit {N}` (where N is a positive integer): extract N as the **teammate limit**, then treat everything after as the **task text**.
3. Otherwise: no limit — treat the entire `$ARGUMENTS` as the **task text**.

### Step 2 — Plan the team

Before spawning anyone, think through the task and decide:

- **How many teammates** are genuinely needed to parallelize this work? Each teammate should have a clearly distinct, independent sub-task. Don't spawn teammates just to have them — only spawn as many as are actually useful.
- **Think granularly.** Don't default to one "frontend agent" and one "backend agent". If the frontend has multiple independent components (e.g., a data table, a form, a chart), each can have its own agent. If the backend has separate concerns (e.g., a repository layer, an API controller, a background job), split those too. The more parallel the work, the faster the result — so lean toward more agents, not fewer, as long as each has a clear and non-overlapping responsibility.
- If a **limit** was passed, cap the teammate count at that number. If the natural split would exceed the limit, consolidate sub-tasks so no teammate is wasted.
- Name each teammate's responsibility in one line.

### Step 3 — Announce the plan

Before starting, print a brief team plan:

```
Team lead: [your role — coordination, synthesis, final output]
Teammate 1: [sub-task]
Teammate 2: [sub-task]
...
```

If a limit was imposed and you had to consolidate, note it: `(limited to N teammates — consolidated X sub-tasks)`

### Step 4 — Execute

Spawn the teammates using the Agent tool (in parallel where independent). Each teammate should receive:
- A focused, self-contained sub-task description
- Enough context to work autonomously (relevant file paths, constraints, conventions)
- A clear deliverable (what to return)

As team lead, you are responsible for:
- Coordinating teammates (resolving conflicts, merging results)
- Doing any work that requires a global view and cannot be isolated
- Synthesizing all teammate outputs into a coherent final result

### Step 5 — Deliver

Present the final, unified result to the user. Don't just dump raw teammate outputs — integrate them. Highlight any conflicts or trade-offs you resolved.

$ARGUMENTS
