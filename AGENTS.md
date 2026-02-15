# Agent Guidelines for Dotfiles Repository

Stow-first dotfiles repo for Linux. GNU Stow creates symlinks from this repo into `$HOME`.

**Repo**: `git@github.com:mark-groves/dotfiles.git`

## Architecture

```
dotfiles/
├── <package>/            # Base stow packages (mirror $HOME structure)
├── hosts/<hostname>/     # Per-host overrides, same mirror structure
│   └── <package>/
├── scripts/              # Management scripts (not stowed)
└── .stow-global-ignore   # Excludes .git, README.md, scripts/ from stow
```

- **Base packages**: Top-level dirs (excluding `hosts/`, `scripts/`, `.git*`) that mirror `$HOME`.
- **Host packages**: Machine-specific overrides in `hosts/<hostname>/<package>/`.
- **Stow order**: Base first, then host-specific overlays. All operations use `--restow`.

## Commands

### Stow Operations
```bash
./scripts/stow.sh base                  # Stow all base packages
./scripts/stow.sh host                  # Stow host packages (current hostname)
./scripts/stow.sh host <hostname>       # Stow specific host's packages
./scripts/stow.sh base -n               # Dry run (also works with host)
stow -n -v -t "$HOME" <package>         # Manual dry run for a single package
stow -t "$HOME" --restow <package>      # Manual restow (idempotent)
stow -t "$HOME" -D <package>            # Unstow a package
```

### Build / Lint / Test

There is no formal build system, test suite, or CI linting configured. No Makefile, justfile, or taskfile exists.

**Validating changes:**
```bash
# Dry-run stow to check for conflicts before applying
stow -n -v -t "$HOME" <package>

# Lint shell scripts manually (shellcheck is not configured but recommended)
shellcheck scripts/stow.sh

# Verify stow is available
stow --version
```

When adding new shell scripts, validate them with `shellcheck` before committing. There is no pre-commit hook enforcement.

## Code Style

### Shell Scripts (Bash)

**Header** -- every script must start with:
```bash
#!/usr/bin/env bash
set -euo pipefail
```

**Functions and structure:**
- Subcommand dispatch via `main()` + `case` statement
- `usage()` function providing `--help` output
- Dependency checks early: `command -v <cmd> >/dev/null 2>&1 || { echo "..."; exit 1; }`

**Variables:**
- Lowercase with underscores: `repo_root`, `host_dir`, `pkg_name`, `dry_run`
- Always quote: `"$variable"`, `"${array[@]}"`
- Declare arrays with `local -a`: `local -a packages=()`, then `packages+=("$item")`
- Use namerefs (`local -n`) for passing arrays to functions

**Control flow:**
- `[[ ]]` for conditionals (never `[ ]`)
- `while IFS= read -r -d '' dir` with `find ... -print0` for null-safe filename handling
- `mapfile -t` to capture command output into arrays
- `case "$1" in -n|--dry-run)` for option parsing

**Path resolution:**
```bash
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
```

**Error handling:**
- Validate directories exist before operating: `[[ ! -d "$dir" ]]`
- Send errors to stderr: `echo "Error: ..." >&2`
- Track failures in arrays and report at end rather than exiting on first failure
- Exit non-zero only when all operations fail; warn on partial failures

### Configuration Files

**TOML (e.g., starship.toml):**
- Group related settings under `[section]` headers
- Use inline comments sparingly; prefer section-level comments
- Define color palettes as named tables (`[palettes.<name>]`) with semantic token names

**Hyprland configs:**
- Split into modular files: `monitors.conf`, `bindings.conf`, `workspaces.conf`, etc.
- Use `bindd` (not `bind`) for application bindings -- includes descriptive labels
- Add Hyprland wiki URL comments for non-obvious settings
- Clear blank lines between logical sections
- Host-specific hardware settings (monitors, input devices) go in `hosts/<hostname>/` only

### Git Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):
```
<type>: <summary>
<type>(<scope>): <summary>
```

**Types**: `feat`, `fix`, `docs`, `refactor`, `chore`, `test`, `ci`
**Avoid**: `init`, `cleanup`, `misc`, or vague summaries like "update" or "changes"

**Rules:**
- Lowercase type and summary
- Summary <= 72 characters
- Scope is optional; use for directory/area (e.g., `scripts`, `hypr`)
- Describe intent/outcome, not files touched
- Wrap body at ~72 chars if present

**Examples:**
```
feat: enable extra application keybindings
fix(scripts): exclude hosts directory from base package discovery
refactor: split hyprland configs into modules
```

## File Management

**Include**: Source-of-truth config files, shell scripts, documentation.
**Exclude** (via `.stow-global-ignore`): `.git`, `README.md`, `scripts/`.
**Never commit**: Generated files, caches, secrets (`.env`, credentials).

### Creating a New Package
```bash
mkdir -p <package>/.config/<app>         # Base package
stow -n -v -t "$HOME" <package>          # Dry run
stow -t "$HOME" <package>                # Apply

# Host override (if needed)
mkdir -p hosts/<hostname>/<package>/.config/<app>
./scripts/stow.sh host
```

## Rules for Agents

1. **Dry-run before stowing**: Always `stow -n -v` first
2. **Mirror `$HOME` exactly**: Package directory structure must match home layout
3. **Base = portable**: No machine-specific settings in base packages
4. **Host = overrides only**: Hardware-specific config goes in `hosts/<hostname>/`
5. **Idempotent scripts**: Safe to run multiple times (`--restow`, `set -euo pipefail`)
6. **No `cd` without error handling**: Resolve paths with `$BASH_SOURCE` or subshells
7. **Check for conflicts**: Verify no existing symlinks clash before creating packages
8. **Preserve patterns**: Match the style of `scripts/stow.sh` for any new scripts

## References

- [GNU Stow](https://www.gnu.org/software/stow/)
- [Hyprland Wiki](https://wiki.hyprland.org/)
