#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

[[ "$(uname -s)" == Linux ]] || die "only Fedora is implemented currently"
[[ -r /etc/os-release ]] || die "cannot identify this operating system"
# shellcheck source=/dev/null
source /etc/os-release
[[ "${ID:-}" == fedora ]] || die "only Fedora is implemented currently; detected ${PRETTY_NAME:-unknown}"
[[ ${EUID:-$(id -u)} -ne 0 ]] || die "run bootstrap as your normal user, not root"

missing_packages=()
command -v ansible-playbook >/dev/null 2>&1 || missing_packages+=(ansible-core)
command -v stow >/dev/null 2>&1 || missing_packages+=(stow)

if [[ ${#missing_packages[@]} -gt 0 ]]; then
  printf 'Bootstrap needs these Fedora packages: %s\n' "${missing_packages[*]}"
  printf 'The following command installs only those prerequisites:\n'
  printf '  sudo dnf install %s\n' "${missing_packages[*]}"

  if [[ ! -t 0 ]]; then
    die "interactive approval is required to install bootstrap prerequisites"
  fi

  read -r -p 'Install the prerequisites now? [y/N] ' reply
  [[ "$reply" =~ ^[Yy]$ ]] || die "prerequisite installation declined"
  sudo dnf install "${missing_packages[@]}"
fi

printf 'Running the Fedora workstation playbook.\n'
ansible_args=()
if ! sudo -n true 2>/dev/null; then
  printf 'System package and repository tasks require your sudo password.\n'
  ansible_args+=(--ask-become-pass)
fi
exec ansible-playbook ansible/playbook.yml "${ansible_args[@]}" "$@"
