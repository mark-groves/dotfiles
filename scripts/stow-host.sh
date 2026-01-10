#!/usr/bin/env bash
set -euo pipefail

# Ensure stow is available before doing any work.
command -v stow >/dev/null 2>&1 || {
  echo "stow is required but not installed. Please install it and retry."
  exit 1
}

# Resolve repo root so the script works from any working directory.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# Use provided hostname override or detect the current host.
host="${1:-$(hostname)}"
host_dir="hosts/$host"

# Ensure the host package root exists.
if [[ ! -d "$host_dir" ]]; then
  echo "Host package not found: $host_dir"
  exit 1
fi

# Discover host-specific packages under hosts/<hostname>.
packages=()
while IFS= read -r -d '' dir; do
  pkg="${dir#./}"
  packages+=("$pkg")
done < <(find "./$host_dir" -maxdepth 1 -mindepth 1 -type d -print0)

# Fail fast if the host has no packages.
if [[ ${#packages[@]} -eq 0 ]]; then
  echo "No host packages found under: $host_dir"
  exit 1
fi

# Restow host packages to ensure idempotent, refreshed symlinks.
stow -t "$HOME" --restow "${packages[@]}"
