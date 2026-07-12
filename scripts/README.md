# Helper scripts

- `check.sh` validates shell, Git, JSON, Ansible, and Stow configuration using
  the tools currently installed.
- `stow.sh` links the packages listed in `stow-packages.txt` into `$HOME`.

Both scripts are safe to invoke directly. Run `stow.sh --dry-run` before a
manual deployment to inspect link conflicts.
