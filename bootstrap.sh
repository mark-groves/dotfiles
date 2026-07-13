#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat << 'EOF'
Usage: bootstrap.sh [options]

Install the portable package profile, then deploy its dotfiles.

Options:
  -n, --dry-run        Preview package and Stow changes
      --provider NAME  Override automatic package-provider detection
      --packages-only  Install packages without deploying dotfiles
      --dotfiles-only  Deploy dotfiles without installing packages
  -h, --help           Show this help message
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dry_run=false
packages_only=false
dotfiles_only=false
provider=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n | --dry-run) dry_run=true ;;
    --provider)
      shift
      [[ $# -gt 0 ]] || die "--provider requires a name"
      provider="$1"
      ;;
    --provider=*) provider="${1#*=}" ;;
    --packages-only) packages_only=true ;;
    --dotfiles-only) dotfiles_only=true ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

"$packages_only" && "$dotfiles_only" &&
  die "--packages-only and --dotfiles-only cannot be used together"
[[ ${EUID:-$(id -u)} -ne 0 ]] || die "run bootstrap as your normal user, not root"

if ! "$dotfiles_only"; then
  package_args=()
  "$dry_run" && package_args+=(--dry-run)
  [[ -z "$provider" ]] || package_args+=(--provider "$provider")
  "$root/scripts/install-packages.sh" "${package_args[@]}"
fi

if ! "$packages_only"; then
  if "$dry_run" && ! command -v stow > /dev/null 2>&1; then
    printf 'GNU Stow is not installed; the package plan above includes it.\n'
    printf 'Would deploy these dotfile packages after installation:\n'
    "$root/scripts/stow.sh" list | sed 's/^/  /'
  else
    stow_args=(base)
    "$dry_run" && stow_args+=(--dry-run)
    "$root/scripts/stow.sh" "${stow_args[@]}"
  fi
fi
