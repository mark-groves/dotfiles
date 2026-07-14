# scripts

Helper scripts for installing the portable package profile and deploying
dotfiles.

| Script | Description |
|--------|-------------|
| `install-packages.sh` | Resolve the shared profile through an OS provider |
| `../ansible/package-providers/fedora.sh` | Detect Fedora and idempotently install missing RPMs |
| `stow.sh` | Deploy or repair portable GNU Stow packages |
| `check.sh` | Validate manifests, scripts, configuration, and a Stow preview |

Package adapters are intentionally small. Each executable adapter accepts:

- `detect`: return success when it supports the current machine.
- `plan <packages...>`: print the non-mutating install plan.
- `install <packages...>`: install only the requested provider package names.

Provider package names and elevated install behavior remain under `ansible/`.
The scripts directory contains only unprivileged dispatch and deployment tools.
