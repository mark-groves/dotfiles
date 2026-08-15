# Package manifests

This directory holds the portable package profile and OS-specific install
adapters. `profile.txt` lists stable application identifiers;
`providers/<provider>.txt` maps those identifiers to concrete package names.

The adapters live here because they perform the elevated package transaction.
The unprivileged dispatcher lives under `scripts/`. Full system provisioning,
repository configuration, drivers, and workstation policy belong in a separate
workstation setup repository.

Current adapters:

- `adapters/fedora.sh` / `providers/fedora.txt`
- `adapters/ubuntu.sh` / `providers/ubuntu.txt`

On Ubuntu, `uv`, `rust-analyzer`, mikefarah `yq`, `herdr`, `codex`, and
`cursor-cli` are satisfied through `scripts/install-user-tools.sh` when apt
cannot provide the expected binary. Ubuntu also overlays the pinned Starship
GitHub release when universe is older than that pin. On Fedora, `starship`
and those same agent CLIs use the same fallback because they are not in the
default repos. Cursor CLI installs as `agent`.
