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
[[ ! -e /run/ostree-booted ]] ||
  die "immutable Fedora variants are not supported; use a mutable Fedora installation"
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
requested_tags=""
expect_tags=false
for arg in "$@"; do
  if "$expect_tags"; then
    requested_tags+="${requested_tags:+,}${arg}"
    expect_tags=false
    continue
  fi
  case "$arg" in
    --tags|-t) expect_tags=true ;;
    --tags=*) requested_tags+="${requested_tags:+,}${arg#--tags=}" ;;
  esac
done

needs_become=true
if [[ -n "$requested_tags" ]]; then
  needs_become=false
  read -r -a selected_tags <<< "${requested_tags//,/ }"
  for tag in "${selected_tags[@]}"; do
    case "$tag" in
      packages|repositories|nvidia|all|tagged|never) needs_become=true ;;
    esac
  done
fi

if "$needs_become" && ! sudo -n true 2>/dev/null; then
  printf 'System package and repository tasks require your sudo password.\n'
  ansible_args+=(--ask-become-pass)
fi
exec ansible-playbook ansible/playbook.yml "${ansible_args[@]}" "$@"
