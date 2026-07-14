# Project Instructions

- Use `scripts/stow.sh` for dotfile deployment and symlink repair.
- Run `scripts/check.sh` before committing implementation changes.
- Keep application configuration portable. Put OS package names and system
  provisioning only under `ansible/`.
- Never commit secrets, resolved 1Password references, access tokens, or private
  keys.
