# stow.sh

Stows base and host-specific packages using GNU Stow.

## Usage

```sh
./scripts/stow.sh <command> [options]
```

## Commands

| Command              | Description                                      |
|----------------------|--------------------------------------------------|
| `base`               | Stow all base packages                           |
| `host [hostname]`    | Stow host-specific packages (default: current hostname) |
| `help`               | Show usage                                       |

## Options

| Option          | Description                                  |
|-----------------|----------------------------------------------|
| `-n, --dry-run` | Show what would be stowed without making changes |

## Examples

```sh
# Stow all base packages
./scripts/stow.sh base

# Dry run for base packages
./scripts/stow.sh base -n

# Stow host packages for the current machine
./scripts/stow.sh host

# Stow host packages for a specific host
./scripts/stow.sh host nexus-unbound
```

## Notes

- Uses `--restow --no-folding` for all stow operations to prevent directory symlinks.
- Base packages are discovered from top-level directories outside `.git*`,
  `.claude`, `hosts`, and `scripts`.
- Host packages are discovered from `hosts/<hostname>/` and must contain at
  least one real file.
- Exits non-zero only if all packages fail; partial failures produce a warning.
