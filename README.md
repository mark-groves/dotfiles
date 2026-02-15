# dotfiles

Simple stow-first dotfiles with idempotent setup.

## Layout
- Top-level directories (excluding `hosts` and `scripts`) are base stow packages.
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

Stow a single host package:
```
stow -t "$HOME" hosts/<hostname>/<package>
```

Restow (idempotent refresh):
```
stow -t "$HOME" --restow hosts/<hostname>/<package>
```

Stow all base packages:
```
./scripts/stow.sh base
```

Stow host-specific packages for this machine:
```
./scripts/stow.sh host
```

Stow a specific host's packages:
```
./scripts/stow.sh host <hostname>
```

## Notes
- Keep only source-of-truth files here; avoid generated artifacts.
- Host packages should only contain overrides, so the base packages stay portable.
