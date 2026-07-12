# Portable development workstation

This repository has two deliberately separate responsibilities:

1. **Dotfiles** configure portable applications through GNU Stow.
2. **Provisioning** installs those applications and their prerequisites through
   an OS-specific Ansible implementation.

Fedora 43 and 44 are the implemented operating systems today. The layout allows
other platform implementations to be added when they can be tested, without
filling the repository with speculative package mappings.

## What is managed

The Fedora developer profile installs:

- Git, GitHub CLI, Neovim/LazyVim, Ghostty, tmux, and Starship
- TypeScript/Node.js/pnpm, Python/uv, Rust, and Go tooling
- C/C++ build and debugging tools
- Podman, Buildah, and Podman Compose
- Cursor, 1Password desktop, and 1Password CLI
- common terminal utilities and JetBrains Mono Nerd Font

NVIDIA drivers are available as an explicit, non-default profile because they
affect kernel modules and may require a reboot.

## Repository layout

```text
ansible/             Fedora provisioning and package mapping
git/                 portable Git configuration
ghostty/             Ghostty configuration
nvim/                LazyVim configuration and plugin lock file
shell/               additive shell fragments and portable helpers
starship/            Starship prompt configuration
tmux/                tmux configuration
scripts/stow.sh      safe Stow wrapper
scripts/check.sh     repository validation
stow-packages.txt    explicit dotfile deployment order
```

Stow package contents mirror paths relative to `$HOME`. Generated application
state, caches, authentication tokens, SSH private keys, and 1Password data must
never be committed.

## First deployment on Fedora

Inspect the complete predicted Ansible change first:

```bash
./bootstrap.sh --check --diff
```

`bootstrap.sh` detects Fedora and offers to install only `ansible-core` and
`stow` when missing. `--check` asks Ansible to predict changes and `--diff`
shows managed-file differences. Some command-based tasks are skipped in check
mode because they cannot safely predict their result.

Apply the default workstation profile:

```bash
./bootstrap.sh
```

Ansible asks for sudo authentication only when repositories or system packages
need it and no passwordless/cached sudo session is available. The script must be
run as the normal desktop user, never with `sudo`.

Run only selected areas with Ansible tags:

```bash
./bootstrap.sh --tags packages
./bootstrap.sh --tags runtimes,fonts
./bootstrap.sh --tags dotfiles
```

Install or verify the optional NVIDIA package set:

```bash
./bootstrap.sh --tags nvidia
```

The NVIDIA task never reboots automatically. Wait for the akmods build to
finish, reboot deliberately, and verify the driver with `nvidia-smi`.

## Dotfiles only

Preview all configured packages:

```bash
./scripts/stow.sh --dry-run --verbose
```

Apply all packages:

```bash
./scripts/stow.sh
```

Apply selected packages:

```bash
./scripts/stow.sh git ghostty
```

The wrapper refuses to run as root and returns a failure if any package cannot
be linked. Package selection is explicit in `stow-packages.txt`, so unrelated
top-level directories cannot accidentally be deployed. Use `--restow` manually
when links need to be rebuilt; routine Ansible runs preserve idempotency.

## Git authentication and signing

Ordinary commits are intentionally unsigned, which keeps unattended agent work
from blocking on a 1Password approval dialog:

```bash
git commit
```

Create a personally signed commit explicitly:

```bash
git cis
```

The `cis` alias invokes `git commit -S` through the portable `op-ssh-sign`
wrapper. The wrapper locates 1Password's signing helper on supported platforms.

For noninteractive fetch and push, authenticate GitHub CLI over HTTPS:

```bash
gh auth login --git-protocol https --web
```

This authenticates with GitHub in a browser. The managed Git configuration
already delegates HTTPS credentials to `gh`. Verify the credential storage
offered by `gh` on each OS; credentials themselves are never managed by these
dotfiles.

## Validation and idempotency

Run repository checks:

```bash
./scripts/check.sh
```

After the first successful deployment, run it again:

```bash
./bootstrap.sh
```

The second run should report no changes. A recurring change is treated as an
idempotency defect and should be fixed rather than documented as normal.

## Adding another operating system

Do not pass Fedora package names directly to another package manager. Add a
tested OS-specific package mapping and task implementation while reusing the
portable Stow packages. The bootstrap dispatcher should reject unsupported
systems until that implementation exists.
