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

On Ubuntu, `uv`, `rust-analyzer`, and mikefarah `yq` are satisfied through
`scripts/install-user-tools.sh` when apt cannot provide the expected binary.
On Fedora, `starship` uses the same fallback because it is not in the default
repos.
