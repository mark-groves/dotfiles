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

# Not shipped in default Fedora repos; satisfied when the binary is on PATH.
user_provided_package() {
  case "$1" in
    starship | herdr | codex | cursor-cli) return 0 ;;
    *) return 1 ;;
  esac
}

user_provided_binary() {
  case "$1" in
    starship) printf 'starship\n' ;;
    herdr) printf 'herdr\n' ;;
    codex) printf 'codex\n' ;;
    cursor-cli) printf 'agent\n' ;;
    *) return 1 ;;
  esac
}

package_installed() {
  local package="$1" binary
  if user_provided_package "$package"; then
    binary="$(user_provided_binary "$package")"
    command -v "$binary" > /dev/null 2>&1
    return
  fi
  rpm -q -- "$package" > /dev/null 2>&1
}

collect_missing() {
  missing_packages=()
  missing_user_tools=()
  local package
  for package in "$@"; do
    [[ "$package" =~ ^[A-Za-z0-9][A-Za-z0-9+_.:-]*$ ]] ||
      die "invalid Fedora package name: $package"
    if package_installed "$package"; then
      continue
    fi
    if user_provided_package "$package"; then
      missing_user_tools+=("$package")
    else
      missing_packages+=("$package")
    fi
  done
}

print_plan() {
  collect_missing "$@"
  if [[ ${#missing_packages[@]} -eq 0 && ${#missing_user_tools[@]} -eq 0 ]]; then
    printf 'All requested Fedora packages are already installed.\n'
    return
  fi

  if [[ ${#missing_packages[@]} -gt 0 ]]; then
    printf 'Would install %d missing Fedora package(s):\n' "${#missing_packages[@]}"
    printf '  sudo dnf install --assumeyes'
    printf ' %q' "${missing_packages[@]}"
    printf '\n'
  fi

  if [[ ${#missing_user_tools[@]} -gt 0 ]]; then
    printf 'Would install %d user-space tool(s) via scripts/install-user-tools.sh:\n' \
      "${#missing_user_tools[@]}"
    printf '  %s\n' "${missing_user_tools[@]}"
  fi
}

install_packages() {
  collect_missing "$@"
  if [[ ${#missing_packages[@]} -eq 0 && ${#missing_user_tools[@]} -eq 0 ]]; then
    printf 'All requested Fedora packages are already installed.\n'
    return
  fi

  if [[ ${#missing_packages[@]} -gt 0 ]]; then
    command -v sudo > /dev/null 2>&1 || die "sudo is required to install Fedora packages"
    sudo dnf install --assumeyes "${missing_packages[@]}"
  fi

  if [[ ${#missing_user_tools[@]} -gt 0 ]]; then
    local root
    root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    "$root/scripts/install-user-tools.sh" "${missing_user_tools[@]}"
  fi
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
