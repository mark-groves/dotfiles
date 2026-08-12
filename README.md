# dotfiles

Portable application packages and configuration, deployed with GNU Stow.

This repository has a deliberately narrow job:

1. Track a small profile of applications and command-line tools.
2. Map that profile to the current operating system's package names.
3. Link portable application configuration into the user's home directory.

Full workstation provisioning—including repositories, drivers, desktop policy,
and system tuning—belongs in a separate repository.

## Managed configuration

The default Stow deployment includes Git, Ghostty, Neovim/LazyVim, Bash, tmux,
Starship, Lazygit, and Herdr. Package contents mirror paths
relative to `$HOME`. The managed Bash startup file loads additive fragments from
`~/.bashrc.d`. If an existing `~/.bashrc` already loads that directory,
deployment preserves it; otherwise Stow stops instead of replacing personal
shell startup commands.

Supported package providers today are Fedora (`dnf`) and Ubuntu (`apt`). Tools
the distro does not ship cleanly fall through to `scripts/install-user-tools.sh`
from the package adapters.

## Bootstrap

Preview the package transaction and dotfile deployment:

```bash
./bootstrap.sh --dry-run
```

On a fresh machine without GNU Stow, this lists the dotfile packages that will
be deployed; after Stow is installed, the same command also checks exact link
changes and conflicts.

Install missing packages and deploy all configured dotfiles:

```bash
./bootstrap.sh
```

The package step is idempotent: each OS adapter checks what is already present
and only installs what is missing. The Stow step always uses `--restow` so it
also repairs managed symlinks.

Run either half independently:

```bash
./bootstrap.sh --packages-only
./bootstrap.sh --dotfiles-only
```

Never run these scripts with `sudo`; the package adapters request elevation only
for the OS package transaction.

After packages are in place, adapters may still call
`scripts/install-user-tools.sh` for profile entries that apt/dnf cannot satisfy
cleanly (for example Starship on Fedora, `uv` on Ubuntu, mikefarah `yq`, and
`rust-analyzer`). You can also run that script directly for the optional lint
binaries:

```bash
./scripts/install-user-tools.sh
```

## Package tracking

List the portable identifiers and their OS package mapping:

```bash
./scripts/install-packages.sh --provider fedora --list
./scripts/install-packages.sh --provider ubuntu --list
```

The package data is split into:

- `packages/profile.txt`: provider-neutral application identifiers.
- `packages/providers/<provider>.txt`: OS package names.
- `packages/adapters/<provider>.sh`: detection, planning, and installation
  behavior.

Ubuntu notes:

- Prefer Ubuntu 26.04+ so `lazygit`, `ghostty`, and `starship` are in universe.
- `uv`, `rust-analyzer`, and mikefarah `yq` are treated as user-space tools
  because apt either omits them or ships a different `yq`.
- `fd` / `bat` may appear as `fdfind` / `batcat`; shell aliases and optional
  `~/.local/bin` shims cover the usual names.

Fedora notes:

- `starship` is not in the default repos, so the Fedora adapter installs it via
  `scripts/install-user-tools.sh` when the binary is missing.
- `ghostty` and `lazygit` expect their usual COPR/third-party repos from
  workstation provisioning.

To add another tested provider, add its mapping and an executable adapter with
the same `detect`, `plan`, and `install` interface. The shared profile and Stow
packages do not change.

## Dotfiles

Preview or deploy the explicit default package list:

```bash
./scripts/stow.sh base --dry-run
./scripts/stow.sh base
```

Deploy selected portable packages:

```bash
./scripts/stow.sh base git nvim
```

`stow-packages.txt` is the source of truth for the default deployment. Keeping
that allowlist separate prevents infrastructure and documentation directories
from being mistaken for dotfile packages.

## Git authentication and signing

Ordinary commits are unsigned so unattended tools do not block on 1Password.
Use `git cis` for an explicitly signed personal commit. GitHub HTTPS credentials
are delegated to `gh auth git-credential` through `~/.local/bin/gh-credential`.
Credentials and private keys are never stored in this repository.

Machine-local Git overrides belong in `~/.config/git/config.local`, which is
included from the tracked config and is not part of this repository.

## Validation

Run the repository checks before committing implementation changes:

```bash
./scripts/check.sh
```
