# Project Instructions

- Use `scripts/stow.sh` for dotfile deployment and symlink repair.
- Run `scripts/check.sh` before committing implementation changes.
- Keep application configuration portable. Put OS package names and install
  adapters only under `packages/`.
- Never commit secrets, resolved 1Password references, access tokens, or private
  keys.
