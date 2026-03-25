---
description: Perform a thorough code review with multiple evaluation passes and alternative implementation research
---

## Help

If `$ARGUMENTS` contains `-h` or `--help`, do NOT run the command. Instead, print the following and stop:

```
/review-code — Thorough code review with multiple evaluation passes

Options:
  -h, --help  Show this help message

Pass a file path or description to review specific code, or omit to review recent changes.
```

## Instructions

Use the `code-review-analyst` agent to perform a comprehensive code review of the specified code or recent changes.

The agent will:
1. Analyze the code with multiple evaluation passes
2. Identify potential improvements and issues
3. Research alternative approaches and implementations
4. Propose optimizations based on best practices

If no specific file or code is mentioned, review the most recently modified files or uncommitted changes in the current project.

$ARGUMENTS
