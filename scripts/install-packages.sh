#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat << 'EOF'
Usage: install-packages.sh [options]

Install the package profile using an operating-system provider.

Options:
  -n, --dry-run        Show the missing packages and install command
  -l, --list           List logical identifiers and provider package names
      --provider NAME  Override automatic provider detection
  -h, --help           Show this help message
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

valid_identifier() {
  [[ "$1" =~ ^[a-z0-9][a-z0-9-]*$ ]]
}

detect_provider() {
  local adapter detected=""
  shopt -s nullglob
  for adapter in "$provider_dir"/*.sh; do
    [[ -x "$adapter" ]] || continue
    if "$adapter" detect > /dev/null 2>&1; then
      [[ -z "$detected" ]] || die "multiple package providers match this system"
      detected="$(basename "$adapter" .sh)"
    fi
  done
  shopt -u nullglob
  [[ -n "$detected" ]] || die "no package provider supports this system; use --provider to inspect one"
  printf '%s\n' "$detected"
}

load_mapping() {
  local manifest="$1" line logical package extra existing index
  [[ -f "$manifest" ]] || die "provider mapping not found: $manifest"

  mapping_ids=()
  mapping_packages=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    read -r logical package extra <<< "$line"
    [[ -n "${logical:-}" ]] || continue
    valid_identifier "$logical" || die "invalid logical package identifier in $manifest: $logical"
    [[ -n "${package:-}" && -z "${extra:-}" ]] ||
      die "expected one package name for $logical in $manifest"
    [[ "$package" =~ ^[A-Za-z0-9][A-Za-z0-9+_.:-]*$ ]] ||
      die "invalid provider package name in $manifest: $package"

    existing=false
    for index in "${!mapping_ids[@]}"; do
      if [[ "${mapping_ids[$index]}" == "$logical" ]]; then
        existing=true
        break
      fi
    done
    "$existing" && die "duplicate mapping for $logical in $manifest"

    mapping_ids+=("$logical")
    mapping_packages+=("$package")
  done < "$manifest"
}

lookup_package() {
  local requested="$1" index
  for index in "${!mapping_ids[@]}"; do
    if [[ "${mapping_ids[$index]}" == "$requested" ]]; then
      printf '%s\n' "${mapping_packages[$index]}"
      return
    fi
  done
  return 1
}

load_profile() {
  local manifest="$1" line logical extra package index
  [[ -f "$manifest" ]] || die "package profile not found: $manifest"

  profile_ids=()
  packages=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    read -r logical extra <<< "$line"
    [[ -n "${logical:-}" ]] || continue
    [[ -z "${extra:-}" ]] || die "expected one logical identifier per line in $manifest"
    valid_identifier "$logical" || die "invalid logical package identifier in $manifest: $logical"
    for index in "${!profile_ids[@]}"; do
      [[ "${profile_ids[$index]}" != "$logical" ]] || die "duplicate profile entry: $logical"
    done
    package="$(lookup_package "$logical")" || die "provider $provider has no mapping for $logical"
    profile_ids+=("$logical")
    packages+=("$package")
  done < "$manifest"

  [[ ${#packages[@]} -gt 0 ]] || die "package profile is empty: $manifest"
}

main() {
  local root provider="" dry_run=false list_only=false adapter mapping profile index
  root="$(repo_root)"
  provider_dir="$root/packages/adapters"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n | --dry-run) dry_run=true ;;
      -l | --list) list_only=true ;;
      --provider)
        shift
        [[ $# -gt 0 ]] || die "--provider requires a name"
        provider="$1"
        ;;
      --provider=*) provider="${1#*=}" ;;
      -h | --help)
        usage
        exit 0
        ;;
      *) die "unknown option: $1" ;;
    esac
    shift
  done

  if [[ -z "$provider" ]]; then
    provider="$(detect_provider)"
  fi
  valid_identifier "$provider" || die "invalid provider name: $provider"

  adapter="$provider_dir/$provider.sh"
  mapping="$root/packages/providers/$provider.txt"
  profile="$root/packages/profile.txt"
  [[ -x "$adapter" ]] || die "package provider adapter is not executable: $adapter"

  load_mapping "$mapping"
  load_profile "$profile"

  printf 'Provider: %s\n' "$provider"
  if "$list_only"; then
    for index in "${!profile_ids[@]}"; do
      printf '%-16s %s\n' "${profile_ids[$index]}" "${packages[$index]}"
    done
    exit 0
  fi

  [[ ${EUID:-$(id -u)} -ne 0 ]] || die "run package installation as your normal user, not root"
  if "$dry_run"; then
    "$adapter" plan "${packages[@]}"
  else
    "$adapter" install "${packages[@]}"
  fi
}

main "$@"
