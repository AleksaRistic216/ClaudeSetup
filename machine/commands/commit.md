---
description: Create a git commit with a short message (up to 50 characters). Use when the user asks to commit changes with a short/concise message.
---

# Quick Commit

When the user asks to commit changes:

1. **Review Changes**: Run `git status` and `git diff` in parallel to see what changes exist
2. **Review Commit History**: Run `git log -5 --oneline` to see recent commit message style
3. **Draft Message**: Create a concise commit message that:
    - Is 50 characters or less
    - Uses present tense ("Add" not "Added")
    - Describes what the change does
    - Follows the project's commit message patterns
4. **Commit**: Add files and commit:
   ```bash
   git add <files> && git commit -m "Your commit message here"
   ```
5. **Verify**: Run `git status` to confirm the commit succeeded

## Important Notes

- Commit as current user
- Keep the main message under 50 characters
- Follow existing commit message patterns in the project
- Don't add any additional information as "written by claude code" or similar

$ARGUMENTS
