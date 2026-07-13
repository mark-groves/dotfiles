#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

mapfile -d '' shell_scripts < <(find scripts -type f -name '*.sh' -print0)
mapfile -d '' git_bins < <(find git/.local/bin -type f -print0)
mapfile -d '' bash_fragments < <(find shell/.bashrc.d -type f -name '*.sh' -print0)

printf 'Checking shell syntax...\n'
bash -n bootstrap.sh shell/.bashrc "${shell_scripts[@]}" "${git_bins[@]}" "${bash_fragments[@]}"

if command -v shellcheck > /dev/null 2>&1; then
  printf 'Running ShellCheck...\n'
  shellcheck bootstrap.sh "${shell_scripts[@]}" "${git_bins[@]}"
  shellcheck --shell=bash shell/.bashrc "${bash_fragments[@]}"
else
  printf 'Skipping ShellCheck (not installed).\n'
fi

printf 'Checking executable scripts...\n'
for script in bootstrap.sh scripts/stow.sh scripts/install-packages.sh scripts/package-providers/*.sh "${git_bins[@]}"; do
  [[ -x "$script" ]] || {
    printf 'Script is not executable: %s\n' "$script" >&2
    exit 1
  }
done

printf 'Checking Git configuration syntax...\n'
git config --file git/.config/git/config --list > /dev/null

printf 'Checking JSON files...\n'
if command -v jq > /dev/null 2>&1; then
  jq empty nvim/.config/nvim/lazy-lock.json
else
  printf 'Skipping JSON validation (jq not installed).\n'
fi

printf 'Checking package profile and Fedora mapping...\n'
./scripts/install-packages.sh --provider fedora --list > /dev/null

printf 'Checking Stow package manifest...\n'
stow_packages=()
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  read -r package extra <<< "$line"
  [[ -n "${package:-}" ]] || continue
  [[ -z "${extra:-}" ]] || {
    printf 'Expected one Stow package per line: %s\n' "$line" >&2
    exit 1
  }
  [[ "$package" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ && -d "$package" ]] || {
    printf 'Invalid or missing Stow package: %s\n' "$package" >&2
    exit 1
  }
  for existing in "${stow_packages[@]}"; do
    [[ "$existing" != "$package" ]] || {
      printf 'Duplicate Stow package: %s\n' "$package" >&2
      exit 1
    }
  done
  stow_packages+=("$package")
done < stow-packages.txt

if command -v stow > /dev/null 2>&1; then
  printf 'Checking Stow deployment...\n'
  ./scripts/stow.sh base --dry-run
else
  printf 'Skipping Stow dry-run (GNU Stow not installed).\n'
fi

printf 'Checking patch whitespace...\n'
git diff --check

printf 'All available checks passed.\n'
