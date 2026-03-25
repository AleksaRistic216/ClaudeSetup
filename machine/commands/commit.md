---
description: Create a git commit with a short message (up to 50 characters). Use when the user asks to commit changes with a short/concise message.
---

# Quick Commit

When the user asks to commit changes:

1. **Review Changes**: Run `git status` and `git diff` in parallel to see what changes exist
2. **Determine Scope**:
   - **Default**: Include ALL uncommitted files — staged, unstaged, and untracked
   - **`-soc` / `--scope-of-change`**: Only include files that were created or modified during the current conversation session. Ignore pre-existing uncommitted changes that were not part of this session's work.
3. **Review Commit History**: Run `git log -5 --oneline` to see recent commit message style
4. **Draft Message**: Create a concise commit message that:
    - Is 50 characters or less
    - Uses present tense ("Add" not "Added")
    - Describes what the change does
    - Follows the project's commit message patterns
5. **Commit**: Stage and commit:
   ```bash
   git add -A && git commit -m "Your commit message here"
   ```
   If `-soc` / `--scope-of-change` was passed, only `git add` the specific files touched in this session instead of `-A`.
6. **Push (if requested)**: If the user passed `-p` or `--push`, run `git push` after the commit succeeds
7. **Verify**: Run `git status` to confirm the commit succeeded

## Help

If `$ARGUMENTS` contains `-h` or `--help`, do NOT run the command. Instead, print the following and stop:

```
/commit — Create a git commit with a concise message (≤50 chars)

Options:
  -p, --push              Push to remote after committing
  -soc, --scope-of-change Only commit files changed during the current session
  -h, --help              Show this help message
```

## Arguments

- `-h` or `--help`: Show help message and exit
- `-p` or `--push`: Push to the remote after committing
- `-soc` or `--scope-of-change`: Only commit files changed during the current session (ignore pre-existing uncommitted changes)

## Important Notes

- Commit as current user
- Keep the main message under 50 characters
- Follow existing commit message patterns in the project
- Don't add any additional information as "written by claude code" or similar

$ARGUMENTS
