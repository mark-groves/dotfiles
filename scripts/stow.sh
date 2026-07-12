#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: stow.sh [options] [package ...]

Link portable configuration packages into the current user's home directory.
With no package arguments, packages are read from stow-packages.txt.

Options:
  -n, --dry-run   Show intended changes without modifying links
  -v, --verbose   Show detailed GNU Stow output
  -R, --restow    Rebuild links (use after files are removed from a package)
  -h, --help      Show this help message

Examples:
  ./scripts/stow.sh --dry-run
  ./scripts/stow.sh
  ./scripts/stow.sh git ghostty
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

load_default_packages() {
  local manifest="$1"

  [[ -f "$manifest" ]] || die "package manifest not found: $manifest"
  mapfile -t packages < <(sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$manifest")
}

main() {
  [[ ${EUID:-$(id -u)} -ne 0 ]] || die "do not run Stow as root or with sudo"
  command -v stow >/dev/null 2>&1 || die "GNU Stow is required; run ./bootstrap.sh first"

  local root dry_run=false verbose=false restow=false
  local -a packages=() stow_args=() failed=()
  root="$(repo_root)"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--dry-run) dry_run=true ;;
      -v|--verbose) verbose=true ;;
      -R|--restow) restow=true ;;
      -h|--help) usage; exit 0 ;;
      -*) die "unknown option: $1" ;;
      *) packages+=("$1") ;;
    esac
    shift
  done

  if [[ ${#packages[@]} -eq 0 ]]; then
    load_default_packages "$root/stow-packages.txt"
  fi
  [[ ${#packages[@]} -gt 0 ]] || die "no Stow packages selected"

  stow_args=(--target "$HOME" --no-folding)
  "$restow" && stow_args+=(--restow)
  "$dry_run" && stow_args+=(--simulate)
  "$verbose" && stow_args+=(--verbose=2)

  cd "$root"
  printf 'Target: %s\n' "$HOME"
  "$dry_run" && printf 'Mode: dry-run\n'

  local package
  for package in "${packages[@]}"; do
    if [[ ! -d "$package" ]]; then
      printf 'Error: package directory does not exist: %s\n' "$package" >&2
      failed+=("$package")
      continue
    fi

    printf 'Stowing %s\n' "$package"
    if ! stow "${stow_args[@]}" "$package"; then
      failed+=("$package")
    fi
  done

  if [[ ${#failed[@]} -gt 0 ]]; then
    printf 'Error: failed packages: %s\n' "${failed[*]}" >&2
    exit 1
  fi

  printf 'Done.\n'
}

main "$@"
