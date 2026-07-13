# Package manifests

This directory is intentionally limited to operating-system-specific package
data. `packages/profile.txt` contains stable application identifiers, while
`packages/providers/<provider>.txt` maps those identifiers to concrete package
names.

The shell dispatcher and provider adapters live under `scripts/`. Full system
provisioning, repository configuration, drivers, and workstation policy belong
in the separate Fedora setup repository.
