#!/usr/bin/env bash
# Resolves the changeset a review panel should look at — unpushed commits, staged, unstaged and
# untracked — and pins it to one base sha so every reviewer sees the identical diff.
# Reads only. Prints an inventory, never a diff.
set -uo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "not a git repository" >&2
  exit 2
}

base=""
base_source=""

if up=$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null) && [ -n "$up" ]; then
  base=$(git merge-base "$up" HEAD 2>/dev/null)
  base_source="merge-base with upstream $up"
fi

if [ -z "$base" ] && def=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null) && [ -n "$def" ]; then
  base=$(git merge-base "$def" HEAD 2>/dev/null)
  base_source="merge-base with $def (no upstream set for this branch)"
fi

if [ -z "$base" ]; then
  for b in origin/master origin/main master main; do
    if git rev-parse --verify --quiet "$b" >/dev/null 2>&1; then
      base=$(git merge-base "$b" HEAD 2>/dev/null)
      [ -n "$base" ] && base_source="merge-base with $b (guessed — no upstream, no origin/HEAD)" && break
    fi
  done
fi

if [ -z "$base" ]; then
  base=$(git rev-parse HEAD)
  base_source="HEAD — WARNING: no upstream or default branch found, so committed work is NOT covered; only the working tree is"
fi

tracked=$(git diff --name-only "$base" 2>/dev/null)
untracked=$(git ls-files --others --exclude-standard)
commits=$(git log --oneline "$base"..HEAD 2>/dev/null)

if [ -z "$tracked" ] && [ -z "$untracked" ]; then
  echo "NOTHING TO REVIEW — no unpushed commits, no staged or unstaged changes, no untracked files."
  echo "BASE $base"
  exit 1
fi

echo "BASE $base"
echo "BASE_SOURCE $base_source"
echo "BRANCH $(git rev-parse --abbrev-ref HEAD)"
echo "REPO $(git rev-parse --show-toplevel)"
echo
echo "=== unpushed commits ==="
if [ -n "$commits" ]; then echo "$commits"; else echo "(none — working tree only)"; fi
echo
echo "=== changed files (git diff --stat \$BASE) ==="
git diff --stat "$base"
echo
echo "=== untracked files (not in any diff — reviewers must read these in full) ==="
if [ -n "$untracked" ]; then echo "$untracked"; else echo "(none)"; fi
echo
echo "=== size ==="
echo "tracked files changed: $(printf '%s' "$tracked" | grep -c . )"
echo "untracked files:       $(printf '%s' "$untracked" | grep -c . )"
echo "lines changed:         $(git diff --shortstat "$base")"
