# dotfiles

Simple GNU Stow-based dotfiles with idempotent setup.

## Layout

- Top-level directories (excluding `hosts`, `scripts`, `.git*`, and `.claude`) are base stow packages.
- Package contents mirror `$HOME` exactly.
- Per-host overrides live under `hosts/<hostname>/<package>` and are stowed after base packages.

Current base packages:

- `git` -> `~/.config/git/config`
- `starship` -> `~/.config/starship.toml`

Example:

```text
hosts/<hostname>/hypr/.config/hypr/...
```

## Usage

Check that GNU Stow is installed:

```sh
stow --version
```

Dry-run first:

```sh
./scripts/stow.sh base -n
./scripts/stow.sh host -n
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

For low-level troubleshooting, this is the equivalent shape for one host
package:

```sh
stow -t "$HOME" --restow --no-folding -d hosts/<hostname> <package>
```

## Notes

- Keep only source-of-truth files here; avoid generated artifacts.
- Host packages should only contain overrides, so the base packages stay portable.
- Use `scripts/stow.sh` for normal refreshes and symlink repairs so base and
  host package discovery stays consistent.
