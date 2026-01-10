# dotfiles

Simple stow-first dotfiles with idempotent setup.

## Layout
- Each top-level directory is a stow package.
- Package contents mirror `$HOME` exactly.

Example:
```
hypr/.config/hypr/...
```

## Usage
Install stow if needed:
```
stow --version
```

Stow a single package:
```
stow -t "$HOME" hypr
```

Restow (idempotent refresh):
```
stow -t "$HOME" --restow hypr
```

Stow everything in this repo:
```
./scripts/stow-all.sh
```

## Notes
- Keep only source-of-truth files here; avoid generated artifacts.
- If you add host-specific overrides, create a separate package like
  `hosts/<hostname>` and stow it after the base package.
