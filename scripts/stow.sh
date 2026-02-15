#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [options]

Commands:
  base                  Stow all base packages
  host [hostname]       Stow host-specific packages (default: current hostname)
  help                  Show this help message

Options:
  -n, --dry-run         Show what would be stowed without making changes

Examples:
  $(basename "$0") base
  $(basename "$0") base -n
  $(basename "$0") host
  $(basename "$0") host nexus-unbound
EOF
}

require_stow() {
  command -v stow >/dev/null 2>&1 || {
    echo "Error: stow is required but not installed. Please install it and retry."
    exit 1
  }
}

resolve_repo_root() {
  local repo_root
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  echo "$repo_root"
}

discover_base_packages() {
  local -a packages=()
  
  while IFS= read -r -d '' dir; do
    pkg="${dir#.}"
    pkg="${pkg#/}"
    packages+=("$pkg")
  done < <(find . -maxdepth 1 -mindepth 1 -type d \
    -not -path './.git*' \
    -not -path './scripts' \
    -not -path './hosts' \
    -print0)
  
  printf '%s\n' "${packages[@]}"
}

discover_host_packages() {
  local hostname="$1"
  local host_dir="hosts/$hostname"
  local -a packages=()
  
  if [[ ! -d "$host_dir" ]]; then
    echo "Error: Host package directory not found: $host_dir" >&2
    exit 1
  fi
  
  while IFS= read -r -d '' dir; do
    # Only include directories that contain actual files (not just subdirs)
    if find "$dir" -type f -print -quit | grep -q .; then
      pkg="${dir#./}"
      packages+=("$pkg")
    fi
  done < <(find "./$host_dir" -maxdepth 1 -mindepth 1 -type d -print0)
  
  printf '%s\n' "${packages[@]}"
}

cmd_base() {
  local repo_root dry_run=false
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--dry-run)
        dry_run=true
        ;;
      *)
        echo "Error: unknown option '$1' for base command" >&2
        exit 1
        ;;
    esac
    shift
  done
  
  repo_root="$(resolve_repo_root)"
  cd "$repo_root"
  
  mapfile -t packages < <(discover_base_packages)
  
  if [[ ${#packages[@]} -eq 0 || -z "${packages[0]:-}" ]]; then
    echo "No stow packages found."
    exit 1
  fi
  
  echo "Stowing base packages: ${packages[*]}"
  
  local -a failed=()
  local -a stow_args=()
  for pkg in "${packages[@]}"; do
    stow_args=(-t "$HOME" --restow)
    [[ "$dry_run" == true ]] && stow_args+=(-n)
    stow_args+=("$pkg")
    
    echo "  $pkg"
    if ! stow "${stow_args[@]}"; then
      failed+=("$pkg")
    fi
  done
  
  handle_results packages failed
}

cmd_host() {
  local repo_root dry_run=false hostname=""
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--dry-run)
        dry_run=true
        ;;
      -*)
        echo "Error: unknown option '$1' for host command" >&2
        exit 1
        ;;
      *)
        if [[ -z "$hostname" ]]; then
          hostname="$1"
        else
          echo "Error: unexpected argument '$1'" >&2
          exit 1
        fi
        ;;
    esac
    shift
  done
  
  [[ -z "$hostname" ]] && hostname="$(hostname)"
  
  repo_root="$(resolve_repo_root)"
  cd "$repo_root"
  
  mapfile -t packages < <(discover_host_packages "$hostname")
  
  if [[ ${#packages[@]} -eq 0 || -z "${packages[0]:-}" ]]; then
    echo "No valid host packages found for: $hostname"
    exit 1
  fi
  
  echo "Stowing host packages for '$hostname': ${packages[*]}"
  
  local -a failed=()
  local -a stow_args=()
  local pkg_dir pkg_name
  for pkg in "${packages[@]}"; do
    stow_args=(-t "$HOME" --restow)
    
    # For host packages, use -d to specify the package directory
    # since package names can't contain slashes
    pkg_dir="${pkg%/*}"   # e.g., hosts/nexus-unbound
    pkg_name="${pkg##*/}" # e.g., hypr
    [[ "$dry_run" == true ]] && stow_args+=(-n)
    stow_args+=(-d "$pkg_dir" "$pkg_name")
    
    echo "  $pkg_name"
    if ! stow "${stow_args[@]}"; then
      failed+=("$pkg")
    fi
  done
  
  handle_results packages failed
}

handle_results() {
  local -n _packages="$1"
  local -n _failed="$2"
  
  # Exit non-zero only if ALL packages failed
  if [[ ${#_failed[@]} -eq ${#_packages[@]} && ${#_packages[@]} -gt 0 ]]; then
    echo "Error: all packages failed to stow"
    exit 1
  fi
  
  if [[ ${#_failed[@]} -gt 0 ]]; then
    echo "Warning: failed to stow: ${_failed[*]}"
  else
    echo "Done."
  fi
}

main() {
  require_stow
  
  [[ $# -eq 0 ]] && {
    usage
    exit 1
  }
  
  local cmd="$1"
  shift
  
  case "$cmd" in
    base)
      cmd_base "$@"
      ;;
    host)
      cmd_host "$@"
      ;;
    help|--help|-h)
      usage
      ;;
    *)
      echo "Error: unknown command '$cmd'" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
