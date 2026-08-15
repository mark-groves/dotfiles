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
    [[ "${ID:-}" == ubuntu || "${ID_LIKE:-}" == *ubuntu* ]]
  ) || return 1

  command -v apt-get > /dev/null 2>&1 && command -v dpkg-query > /dev/null 2>&1
}

# Profile entries that Ubuntu may not ship as apt packages with the same
# semantics as Fedora. Satisfied when the expected binary is already on PATH.
user_provided_package() {
  case "$1" in
    rust-analyzer | yq | uv | herdr | codex | cursor-cli) return 0 ;;
    *) return 1 ;;
  esac
}

user_provided_binary() {
  case "$1" in
    rust-analyzer) printf 'rust-analyzer\n' ;;
    yq) printf 'yq\n' ;;
    uv) printf 'uv\n' ;;
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
    command -v "$binary" > /dev/null 2>&1 || return 1
    # Ubuntu's apt "yq" is kislyuk/yq; this profile expects mikefarah/yq.
    if [[ "$package" == yq ]]; then
      yq --version 2> /dev/null | grep -qi mikefarah
      return
    fi
    return 0
  fi
  dpkg-query --status -- "$package" > /dev/null 2>&1
}

collect_missing() {
  missing_packages=()
  missing_user_tools=()
  local package
  for package in "$@"; do
    [[ "$package" =~ ^[A-Za-z0-9][A-Za-z0-9+_.:-]*$ ]] ||
      die "invalid Ubuntu package name: $package"
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
    printf 'All requested Ubuntu packages are already installed.\n'
    return
  fi

  if [[ ${#missing_packages[@]} -gt 0 ]]; then
    printf 'Would install %d missing Ubuntu package(s):\n' "${#missing_packages[@]}"
    printf '  sudo apt-get install --yes'
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
  local root
  root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

  if [[ ${#missing_packages[@]} -eq 0 && ${#missing_user_tools[@]} -eq 0 ]]; then
    printf 'All requested Ubuntu packages are already installed.\n'
    "$root/scripts/install-user-tools.sh" ubuntu-shims starship
    return
  fi

  if [[ ${#missing_packages[@]} -gt 0 ]]; then
    command -v sudo > /dev/null 2>&1 || die "sudo is required to install Ubuntu packages"
    sudo apt-get update
    sudo apt-get install --yes "${missing_packages[@]}"
  fi

  if [[ ${#missing_user_tools[@]} -gt 0 ]]; then
    "$root/scripts/install-user-tools.sh" "${missing_user_tools[@]}"
  fi

  # Debian package names use fdfind/batcat; keep common names available.
  # Universe Starship can lag the pinned GitHub release used by the prompt config.
  "$root/scripts/install-user-tools.sh" ubuntu-shims starship
}

case "${1:-}" in
  detect)
    is_supported
    ;;
  plan)
    shift
    is_supported || die "this provider requires Ubuntu with apt-get"
    print_plan "$@"
    ;;
  install)
    shift
    is_supported || die "this provider requires Ubuntu with apt-get"
    install_packages "$@"
    ;;
  *)
    die "provider usage: $(basename "$0") <detect|plan|install> [package ...]"
    ;;
esac
