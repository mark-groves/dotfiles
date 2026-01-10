# dotfiles

Simple stow-first dotfiles with idempotent setup.

## Layout
- Each top-level directory is a stow package.
- Package contents mirror `$HOME` exactly.
- Per-host overrides live under `hosts/<hostname>/<package>` and are stowed after base packages.

Example:
```
hosts/<hostname>/hypr/.config/hypr/...
```

## Usage
Install stow if needed:
```
stow --version
```

Stow a single package:
```
stow -t "$HOME" hosts/<hostname>
```

Restow (idempotent refresh):
```
stow -t "$HOME" --restow hosts/<hostname>
```

Stow all base packages:
```
./scripts/stow-base.sh
```

Stow host-specific packages for this machine:
```
./scripts/stow-host.sh
```

Stow a specific host's packages:
```
./scripts/stow-host.sh <hostname>
```

## Notes
- Keep only source-of-truth files here; avoid generated artifacts.
- Host packages should only contain overrides, so the base packages stay portable.
