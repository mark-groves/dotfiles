# Agent Guidelines for Dotfiles Repository

This document provides coding agents with essential information about this dotfiles repository structure, workflows, and conventions.

## Repository Overview

This is a stow-first dotfiles repository for managing Linux system configuration files with per-host overrides. The repository uses GNU Stow to create symlinks from the repo to `$HOME`.

**Repository**: `git@github.com:mark-groves/dotfiles.git`

## Architecture

### Directory Structure
```
dotfiles/
├── hosts/                    # Host-specific overrides
│   └── <hostname>/          # Per-machine packages
│       └── <package>/       # Mirrors $HOME structure
├── scripts/                 # Management scripts
├── <package>/               # Base stow packages (mirror $HOME)
└── README.md
```

### Key Concepts
- **Base packages**: Top-level directories (excluding `hosts/` and `scripts/`) that mirror `$HOME` structure
- **Host packages**: Machine-specific overrides in `hosts/<hostname>/<package>/`
- **Stow workflow**: Base packages are stowed first, then host-specific packages overlay them
- **Idempotency**: All stow operations use `--restow` for safe, repeatable execution

## Commands

### Stow Operations
```bash
# Stow all base packages
./scripts/stow.sh base

# Stow host-specific packages for current machine
./scripts/stow.sh host

# Stow specific host's packages
./scripts/stow.sh host <hostname>

# Manual stow of single package
stow -t "$HOME" <package>

# Manual restow (idempotent refresh)
stow -t "$HOME" --restow <package>

# Unstow a package
stow -t "$HOME" -D <package>
```

### Git Operations
```bash
# Check repository status
git status

# View recent commits
git log --oneline -10

# Check what would be stowed
stow -n -v -t "$HOME" <package>
```

### Verification
```bash
# Verify stow is installed
stow --version

# List available base packages
ls -d */ | grep -v hosts | grep -v scripts

# List host-specific packages
ls -la hosts/<hostname>/

# Find config files in a package
find hosts/<hostname>/<package> -type f
```

## Code Style and Conventions

### Shell Scripts (Bash)

**Shebang and Options**
```bash
#!/usr/bin/env bash
set -euo pipefail
```
- Always use `#!/usr/bin/env bash` (not `/bin/bash`)
- Set strict mode: `-e` (exit on error), `-u` (error on unset vars), `-o pipefail` (catch pipe failures)

**Error Handling**
```bash
# Check for required commands before proceeding
command -v stow >/dev/null 2>&1 || {
  echo "stow is required but not installed. Please install it and retry."
  exit 1
}

# Validate directories exist
if [[ ! -d "$host_dir" ]]; then
  echo "Host package not found: $host_dir"
  exit 1
fi
```

**Path Resolution**
```bash
# Always resolve repo root for script portability
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
```

**Variables and Quoting**
- Use lowercase for local variables: `packages`, `host_dir`, `repo_root`
- Always quote variables: `"$variable"`, `"${array[@]}"`
- Use arrays for lists: `packages=()` then `packages+=("$item")`

**Control Flow**
- Use `[[ ]]` for conditionals (not `[ ]`)
- Prefer `while IFS= read -r` for reading input
- Use `-print0` with `find` and `-d ''` with `read` for safe filename handling

### Configuration Files

**Hyprland Configs**
- Use descriptive comments explaining what each section does
- Include references to official documentation where applicable
- Group related settings together (workspaces, monitors, input, bindings)
- Use `bindd` for application bindings with descriptive labels
- Format: clear spacing between logical sections

**File Organization**
- Split large configs into modular files (e.g., `monitors.conf`, `bindings.conf`, `workspaces.conf`)
- Keep host-specific settings in `hosts/<hostname>/` packages only
- Base packages should remain portable across machines

### Git Commit Messages

Follow Conventional Commits (https://www.conventionalcommits.org/):
```
<type>: <summary>
<type>(<scope>): <summary>
```

**Recommended Types**
- `feat`: new user-visible change
- `fix`: bug fix
- `docs`: documentation-only change
- `refactor`: code change without behavior change
- `chore`: tooling, config, or meta updates
- `test`: add or update tests
- `ci`: CI or automation changes

**Avoid**
- `init`, `cleanup`, `misc`, or ambiguous custom types
- Vague summaries like "update" or "changes"

**Examples**
```
feat: enable extra application keybindings
fix(scripts): exclude hosts directory from base package discovery
docs: clarify base package layout exclusions
refactor: split hyprland configs into modules
```

**Guidelines**
- Use lowercase for type and summary
- Keep summary ≤ 72 characters
- Use scope sparingly for directory or area (e.g., `scripts`, `hypr`)
- Describe intent/outcome, not just files touched
- Wrap body at ~72 chars if needed, include rationale

## File Management

### Files to Include
- Source-of-truth configuration files
- Shell scripts for automation
- Documentation (README.md files)

### Files to Exclude (via `.stow-global-ignore`)
```
^\.git(/|$)
^README\.md$
^scripts(/|$)
```
- Git metadata
- README files (documentation, not config)
- Scripts directory (not part of $HOME)
- Generated artifacts or cache files

### Package Creation Workflow

1. **Create base package**:
   ```bash
   mkdir -p <package>/.config/<app>
   # Add config files mirroring $HOME structure
   ```

2. **Test stowing**:
   ```bash
   stow -n -v -t "$HOME" <package>  # Dry run
   stow -t "$HOME" <package>         # Actual stow
   ```

3. **Create host override** (if needed):
   ```bash
   mkdir -p hosts/<hostname>/<package>/.config/<app>
   # Add host-specific overrides
   ./scripts/stow.sh host
   ```

## Best Practices

### For Agents Working in This Repository

1. **Always verify before stowing**: Use `stow -n -v` for dry runs
2. **Maintain the mirror structure**: Packages must exactly mirror `$HOME`
3. **Keep base packages portable**: Host-specific settings go in `hosts/<hostname>/`
4. **Document non-obvious changes**: Add comments in configs and use Conventional Commits with the recommended types above
5. **Test idempotency**: Scripts should be safe to run multiple times
6. **Preserve existing patterns**: Follow established conventions in scripts and configs
7. **Check for conflicts**: Before creating new packages, verify no symlink conflicts
8. **Validate paths**: Always use absolute paths or properly resolve relative paths

### Common Pitfalls to Avoid

- Don't add generated files or cache directories
- Don't break the `$HOME` mirror structure in packages
- Don't hardcode paths that should be host-specific
- Don't modify base packages for machine-specific needs (use host overrides)
- Don't skip the `set -euo pipefail` in bash scripts
- Don't use `cd` without proper error handling

## Reference

- **Stow Documentation**: https://www.gnu.org/software/stow/
- **Hyprland Wiki**: https://wiki.hyprland.org/
- **Repository README**: See `README.md` for user-facing documentation
