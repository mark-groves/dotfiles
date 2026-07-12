#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

printf 'Checking shell syntax...\n'
bash -n bootstrap.sh scripts/stow.sh scripts/check.sh shell/.local/bin/* \
  shell/.bashrc.d/*.sh

if command -v shellcheck >/dev/null 2>&1; then
  printf 'Running ShellCheck...\n'
  shellcheck bootstrap.sh scripts/stow.sh scripts/check.sh shell/.local/bin/*
  shellcheck --shell=bash shell/.bashrc.d/*.sh
else
  printf 'Skipping ShellCheck (not installed).\n'
fi

printf 'Checking Git configuration syntax...\n'
git config --file git/.gitconfig --list >/dev/null

printf 'Checking JSON files...\n'
jq empty nvim/.config/nvim/lazy-lock.json

printf 'Checking Stow package manifest...\n'
while IFS= read -r package; do
  package="${package%%#*}"
  package="${package//[[:space:]]/}"
  [[ -z "$package" ]] && continue
  [[ -d "$package" ]] || {
    printf 'Missing Stow package: %s\n' "$package" >&2
    exit 1
  }
done < stow-packages.txt

if command -v ansible-playbook >/dev/null 2>&1; then
  printf 'Checking Ansible syntax...\n'
  ansible-playbook ansible/playbook.yml --syntax-check
else
  printf 'Skipping Ansible syntax check (ansible-core not installed).\n'
fi

if command -v stow >/dev/null 2>&1; then
  printf 'Checking Stow deployment...\n'
  ./scripts/stow.sh --dry-run
else
  printf 'Skipping Stow dry-run (GNU Stow not installed).\n'
fi

printf 'All available checks passed.\n'
