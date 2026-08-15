#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
export GIT_CONFIG_GLOBAL=/dev/null

shell_scripts=()
while IFS= read -r -d '' file; do
  shell_scripts+=("$file")
done < <(find scripts -type f -name '*.sh' -print0)

provider_scripts=()
while IFS= read -r -d '' file; do
  provider_scripts+=("$file")
done < <(find packages/adapters -type f -name '*.sh' -print0)

git_bins=()
while IFS= read -r -d '' file; do
  git_bins+=("$file")
done < <(find git/.local/bin -type f -print0)

user_bins=("${git_bins[@]}")
if [[ -d shell/.local/bin ]]; then
  while IFS= read -r -d '' file; do
    user_bins+=("$file")
  done < <(find shell/.local/bin -type f -print0)
fi

bash_fragments=()
while IFS= read -r -d '' file; do
  bash_fragments+=("$file")
done < <(find shell/.bashrc.d -type f -name '*.sh' -print0)

printf 'Checking shell syntax...\n'
bash -n bootstrap.sh shell/.bashrc "${shell_scripts[@]}" "${provider_scripts[@]}" \
  "${user_bins[@]}" "${bash_fragments[@]}"

if command -v shellcheck > /dev/null 2>&1; then
  printf 'Running ShellCheck...\n'
  shellcheck bootstrap.sh "${shell_scripts[@]}" "${provider_scripts[@]}" "${user_bins[@]}"
  shellcheck --shell=bash shell/.bashrc "${bash_fragments[@]}"
else
  printf 'Skipping ShellCheck (not installed).\n'
fi

printf 'Checking executable scripts...\n'
for script in bootstrap.sh scripts/stow.sh scripts/install-packages.sh \
  scripts/install-user-tools.sh "${provider_scripts[@]}" "${user_bins[@]}"; do
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

printf 'Checking YAML files...\n'
if command -v yq > /dev/null 2>&1; then
  yq -e '.' lazygit/.config/lazygit/tokyonight_night.yml > /dev/null
  yq -e '.' lazygit/.config/lazygit/tokyonight_day.yml > /dev/null
  yq -e '.' eza/.config/eza/night/theme.yml > /dev/null
  yq -e '.' eza/.config/eza/day/theme.yml > /dev/null
else
  printf 'Skipping YAML validation (yq not installed).\n'
fi

printf 'Checking package profile and provider mappings...\n'
./scripts/install-packages.sh --provider fedora --list > /dev/null
./scripts/install-packages.sh --provider ubuntu --list > /dev/null

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
  stow_home="$(mktemp -d)"
  trap 'rm -rf "$stow_home"' EXIT
  HOME="$stow_home" ./scripts/stow.sh base --dry-run
  rm -rf "$stow_home"
  trap - EXIT
else
  printf 'Skipping Stow dry-run (GNU Stow not installed).\n'
fi

printf 'Checking patch whitespace...\n'
git diff --check

printf 'All available checks passed.\n'
