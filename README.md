# dotfiles

Portable application packages and configuration, deployed with GNU Stow.

This repository has a deliberately narrow job:

1. Track a small profile of applications and command-line tools.
2. Map that profile to the current operating system's package names.
3. Link portable application configuration into the user's home directory.

Full Fedora workstation provisioning—including repositories, drivers, desktop
policy, and system tuning—belongs in a separate repository.

## Managed configuration

The default Stow deployment includes Git, Ghostty, Neovim/LazyVim, Bash, tmux,
and Starship. Package contents mirror paths relative to `$HOME`. The managed
Bash startup file loads additive fragments from `~/.bashrc.d`. If an existing
`~/.bashrc` already loads that directory, deployment preserves it; otherwise
Stow stops instead of replacing personal shell startup commands.

The Fedora package profile installs the core command-line applications and
utilities available from the configured DNF repositories on mutable Fedora
installations. Ghostty and Starship configuration is tracked here, but their
third-party repository or binary setup is intentionally left to workstation
provisioning.

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

The package step is idempotent: the Fedora adapter checks installed RPMs and
invokes DNF only for missing packages. The Stow step always uses `--restow` so
it also repairs managed symlinks.

Run either half independently:

```bash
./bootstrap.sh --packages-only
./bootstrap.sh --dotfiles-only
```

Never run these scripts with `sudo`; the Fedora adapter requests elevation only
for the DNF transaction.

## Package tracking

List the portable identifiers and their Fedora package mapping:

```bash
./scripts/install-packages.sh --provider fedora --list
```

The package data is split into:

- `ansible/packages/profile.txt`: provider-neutral application identifiers.
- `ansible/packages/providers/fedora.txt`: Fedora package names.
- `ansible/package-providers/fedora.sh`: Fedora detection, planning, and
  installation behavior.

To add another tested provider, add its mapping and an executable adapter with
the same `detect`, `plan`, and `install` interface. The shared profile and
Stow packages do not change.

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

Host-specific configuration remains available when needed:

```bash
./scripts/stow.sh host
./scripts/stow.sh host nexus-unbound
```

`stow-packages.txt` is the source of truth for the default deployment. Keeping
that allowlist separate prevents infrastructure and documentation directories
from being mistaken for dotfile packages.

## Git authentication and signing

Ordinary commits are unsigned so unattended tools do not block on 1Password.
Use `git cis` for an explicitly signed personal commit. GitHub HTTPS credentials
are delegated to `gh auth git-credential`; credentials and private keys are
never stored in this repository.

## Validation

Run the repository checks before committing implementation changes:

```bash
./scripts/check.sh
```
