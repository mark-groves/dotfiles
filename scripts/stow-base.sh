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

# Discover top-level package directories to stow.
packages=()
while IFS= read -r -d '' dir; do
  pkg="${dir#./}"
  packages+=("$pkg")
done < <(find . -maxdepth 1 -mindepth 1 -type d -not -path './.git*' -not -path './scripts' -not -path './hosts' -print0)

# Fail fast if nothing is stowable.
if [[ ${#packages[@]} -eq 0 ]]; then
  echo "No stow packages found."
  exit 1
fi

# Restow all packages to ensure idempotent, refreshed symlinks.
stow -t "$HOME" --restow "${packages[@]}"
