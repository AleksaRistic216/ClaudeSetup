# ConEmu Configuration

Custom ConEmu terminal setup applied by the `/setup` command on Windows.

## What Gets Configured

### Font
- **JetBrains Mono** — full Unicode coverage, ligature support

### Zoom
| Action       | Shortcut        |
|-------------|-----------------|
| Zoom in     | `Ctrl+Shift+=`  |
| Zoom out    | `Ctrl+-`        |

### Panel Splitting
| Action           | Shortcut     |
|-----------------|--------------|
| Split horizontal | `Ctrl+T`     |
| Split vertical   | `Ctrl+Alt+T` |
| Close panel      | `Ctrl+W`     |

### Panel Navigation (focus)
| Action      | Shortcut            |
|------------|---------------------|
| Focus up   | `Ctrl+Alt+PgUp`    |
| Focus down | `Ctrl+Alt+PgDn`    |
| Focus left | `Ctrl+Alt+Home`    |
| Focus right| `Ctrl+Alt+End`     |

### Panel Resize
| Action       | Shortcut |
|-------------|----------|
| Resize left | `Alt+J`  |
| Resize up   | `Alt+K`  |
| Resize right| `Alt+L`  |
| Resize down | `Alt+;`  |

### Display
- Inactive (unfocused) panels are dimmed with a fade effect for clear visual focus indication

## Script

The setup is performed by `machine/conemu/setup-conemu.ps1` which:
1. Checks if ConEmu is installed; installs via `winget` if missing
2. Locates `ConEmu.xml` in standard paths
3. Patches all shortcut and display settings listed above
4. Is idempotent — safe to re-run at any time

## Prerequisites
- Windows OS
- [JetBrains Mono](https://www.jetbrains.com/lp/mono/) font installed
- ConEmu must have been launched at least once (to generate `ConEmu.xml`)
