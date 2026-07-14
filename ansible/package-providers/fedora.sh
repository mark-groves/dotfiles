#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

is_supported() {
  [[ "$(uname -s)" == Linux ]] || return 1
  [[ -r /etc/os-release ]] || return 1

  (
    # shellcheck source=/dev/null
    source /etc/os-release
    [[ "${ID:-}" == fedora ]]
  ) || return 1

  [[ ! -e /run/ostree-booted ]] || return 1
  command -v dnf > /dev/null 2>&1 && command -v rpm > /dev/null 2>&1
}

collect_missing() {
  missing_packages=()
  local package
  for package in "$@"; do
    [[ "$package" =~ ^[A-Za-z0-9][A-Za-z0-9+_.:-]*$ ]] ||
      die "invalid Fedora package name: $package"
    rpm -q -- "$package" > /dev/null 2>&1 || missing_packages+=("$package")
  done
}

print_plan() {
  collect_missing "$@"
  if [[ ${#missing_packages[@]} -eq 0 ]]; then
    printf 'All requested Fedora packages are already installed.\n'
    return
  fi

  printf 'Would install %d missing Fedora package(s):\n' "${#missing_packages[@]}"
  printf '  sudo dnf install --assumeyes'
  printf ' %q' "${missing_packages[@]}"
  printf '\n'
}

install_packages() {
  collect_missing "$@"
  if [[ ${#missing_packages[@]} -eq 0 ]]; then
    printf 'All requested Fedora packages are already installed.\n'
    return
  fi

  command -v sudo > /dev/null 2>&1 || die "sudo is required to install Fedora packages"
  sudo dnf install --assumeyes "${missing_packages[@]}"
}

case "${1:-}" in
  detect)
    is_supported
    ;;
  plan)
    shift
    is_supported || die "this provider requires a mutable Fedora installation with dnf"
    print_plan "$@"
    ;;
  install)
    shift
    is_supported || die "this provider requires a mutable Fedora installation with dnf"
    install_packages "$@"
    ;;
  *)
    die "provider usage: $(basename "$0") <detect|plan|install> [package ...]"
    ;;
esac
