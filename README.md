# dotfiles

Simple stow-first dotfiles with idempotent setup.

## Layout

- Top-level directories (excluding `hosts`, `scripts`, `.git`, `.github`, and `.claude`) are base stow packages.
- Package contents mirror `$HOME` exactly.
- Per-host overrides live under `hosts/<hostname>/<package>` and are stowed after base packages.

Example:

```text
hosts/<hostname>/hypr/.config/hypr/...
```

## Usage

Install stow if needed:

```sh
stow --version
```

Stow a single host package:

```sh
stow -t "$HOME" -d hosts/<hostname> <package>
```

Restow (idempotent refresh):

```sh
stow -t "$HOME" --restow -d hosts/<hostname> <package>
```

Stow all base packages:

```sh
./scripts/stow.sh base
```

Stow host-specific packages for this machine:

```sh
./scripts/stow.sh host
```

Stow a specific host's packages:

```sh
./scripts/stow.sh host <hostname>
```

## Notes

- Keep only source-of-truth files here; avoid generated artifacts.
- Host packages should only contain overrides, so the base packages stay portable.
