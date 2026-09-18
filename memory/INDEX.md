# Memory Index

This directory stores persistent context so Claude doesn't ask the same questions twice.
Synced across machines via git — run `git pull` to get the latest.

## Files

- [locations.md](locations.md) — URLs, servers, project management tools, workspaces
- [preferences.md](preferences.md) — How you like things done
- [context/](context/) — Per-project or per-task context files
  - [dx-build.md](context/dx-build.md) — How to build DevExpress sources (MSBuild paths, FW vs NetCore)
  - [rider-winforms-designer.md](context/rider-winforms-designer.md) — Fix: Rider WinForms designer missing — add SubType=Form + DependentUpon metadata to .csproj
