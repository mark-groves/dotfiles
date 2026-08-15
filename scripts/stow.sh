#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat << 'EOF'
Usage: stow.sh <command> [options] [package ...]

Commands:
  base                  Deploy portable packages from stow-packages.txt
  list                  List the default portable packages without deploying
  help                  Show this help message

Options:
  -n, --dry-run         Preview changes without modifying links
  -v, --verbose         Show detailed GNU Stow output

Examples:
  ./scripts/stow.sh base --dry-run
  ./scripts/stow.sh base
  ./scripts/stow.sh base git ghostty
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

valid_name() {
  [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]
}

load_default_packages() {
  local manifest="$1" line package extra
  [[ -f "$manifest" ]] || die "Stow package manifest not found: $manifest"

  default_packages=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    read -r package extra <<< "$line"
    [[ -n "${package:-}" ]] || continue
    [[ -z "${extra:-}" ]] || die "expected one Stow package per line in $manifest"
    valid_name "$package" || die "invalid Stow package name in $manifest: $package"
    default_packages+=("$package")
  done < "$manifest"

  [[ ${#default_packages[@]} -gt 0 ]] || die "Stow package manifest is empty: $manifest"
}

normalize_path() {
  local path="$1" part
  local -a parts normalized=()
  IFS='/' read -r -a parts <<< "$path"
  for part in "${parts[@]}"; do
    case "$part" in
      '' | .) ;;
      ..)
        [[ ${#normalized[@]} -eq 0 ]] || unset "normalized[$((${#normalized[@]} - 1))]"
        ;;
      *) normalized+=("$part") ;;
    esac
  done
  printf '/%s' "$(
    IFS=/
    printf '%s' "${normalized[*]}"
  )"
}

link_points_to() {
  local link="$1" expected="$2" target
  [[ -L "$link" ]] || return 1
  target="$(readlink "$link")" || return 1
  [[ "$target" == /* ]] || target="$(dirname "$link")/$target"
  [[ "$(normalize_path "$target")" == "$(normalize_path "$expected")" ]]
}

package_selected() {
  local requested="$1" package
  shift
  for package in "$@"; do
    [[ "$package" != "$requested" ]] || return 0
  done
  return 1
}

remove_obsolete_links() {
  local root="$1" dry_run="$2" owner link expected replacement
  shift 2
  planned_ignores=()
  local -a migrations=(
    "git|$HOME/.gitconfig|$root/git/.gitconfig"
    "ghostty|$HOME/.config/ghostty/config.ghostty|$root/ghostty/.config/ghostty/config.ghostty"
    "ghostty|$HOME/.config/ghostty/config|$root/ghostty/.config/ghostty/config.ghostty|^\\.config/ghostty/config$"
    "git|$HOME/.local/bin/gh-credential|$root/shell/.local/bin/gh-credential|^\\.local/bin/gh-credential$"
    "git|$HOME/.local/bin/op-ssh-sign|$root/shell/.local/bin/op-ssh-sign"
    "git|$HOME/.local/bin/op-ssh-sign|$root/git/.local/bin/op-ssh-sign"
  )

  for migration in "${migrations[@]}"; do
    IFS='|' read -r owner link expected replacement <<< "$migration"
    package_selected "$owner" "$@" || continue
    if link_points_to "$link" "$expected"; then
      printf 'UNLINK: %s (obsolete dotfile path)\n' "$link"
      if "$dry_run"; then
        if [[ -n "${replacement:-}" ]]; then
          printf 'RELINK: %s (during %s deployment)\n' "$link" "$owner"
          planned_ignores+=("$owner|$replacement")
        fi
      else
        rm -- "$link"
      fi
    fi
  done
}

bashrc_sources_fragments() {
  local bashrc="$1"
  [[ -r "$bashrc" ]] || return 1
  awk '
    /^[[:space:]]*#/ { next }
    $1 == "for" && $3 == "in" && $0 ~ /bashrc\.d\/\*(\.sh)?([;"[:space:]]|$)/ {
      loop_variable = $2
    }
    $1 == "." || $1 == "source" {
      argument = $2
      gsub(/^"|"$/, "", argument)
      if (loop_variable != "" && argument == "$" loop_variable) {
        found = 1
      }
    }
    $1 == "done" { loop_variable = "" }
    END { exit found ? 0 : 1 }
  ' "$bashrc"
}

dry_run_requested() {
  local argument
  for argument in "$@"; do
    case "$argument" in
      -n | --dry-run) return 0 ;;
    esac
  done
  return 1
}

stow_base() {
  local root="$1" dry_run="$2" verbose="$3"
  shift 3
  local -a packages=("$@") stow_args package_args failed=()
  local package planned_ignore migration_owner ignore

  stow_args=(--dir "$root" --target "$HOME" --restow --no-folding)
  "$dry_run" && stow_args+=(--simulate)
  "$verbose" && stow_args+=(--verbose=2)

  remove_obsolete_links "$root" "$dry_run" "${packages[@]}"
  printf 'Target: %s\n' "$HOME"
  "$dry_run" && printf 'Mode: dry-run\n'

  for package in "${packages[@]}"; do
    valid_name "$package" || {
      printf 'Error: invalid Stow package name: %s\n' "$package" >&2
      failed+=("$package")
      continue
    }
    [[ -d "$root/$package" ]] || {
      printf 'Error: Stow package directory does not exist: %s\n' "$package" >&2
      failed+=("$package")
      continue
    }

    printf 'Stowing %s\n' "$package"
    package_args=("${stow_args[@]}")
    for planned_ignore in "${planned_ignores[@]}"; do
      IFS='|' read -r migration_owner ignore <<< "$planned_ignore"
      [[ "$migration_owner" != "$package" ]] || package_args+=(--ignore="$ignore")
    done
    if [[ "$package" == shell && (-e "$HOME/.bashrc" || -L "$HOME/.bashrc") ]] &&
      ! link_points_to "$HOME/.bashrc" "$root/shell/.bashrc"; then
      if bashrc_sources_fragments "$HOME/.bashrc"; then
        printf 'Keeping existing .bashrc (it already loads ~/.bashrc.d).\n'
        package_args+=(--ignore='^\.bashrc$')
      else
        printf 'Error: existing .bashrc does not load ~/.bashrc.d: %s\n' "$HOME/.bashrc" >&2
        failed+=("$package")
        continue
      fi
    fi
    stow "${package_args[@]}" "$package" || failed+=("$package")
  done

  [[ ${#failed[@]} -eq 0 ]] || die "failed Stow packages: ${failed[*]}"

  if ! "$dry_run" && package_selected bat "${packages[@]}" && command -v bat > /dev/null 2>&1; then
    printf 'Rebuilding bat theme cache...\n'
    env -u XDG_CONFIG_HOME -u XDG_CACHE_HOME bat cache --build
  fi

  printf 'Done.\n'
}

cmd_base() {
  local root dry_run=false verbose=false
  local -a packages=()
  root="$(repo_root)"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n | --dry-run) dry_run=true ;;
      -v | --verbose) verbose=true ;;
      -*) die "unknown base option: $1" ;;
      *) packages+=("$1") ;;
    esac
    shift
  done

  if [[ ${#packages[@]} -eq 0 ]]; then
    load_default_packages "$root/stow-packages.txt"
    packages=("${default_packages[@]}")
  fi

  stow_base "$root" "$dry_run" "$verbose" "${packages[@]}"
}

cmd_list() {
  local root
  root="$(repo_root)"
  load_default_packages "$root/stow-packages.txt"
  printf '%s\n' "${default_packages[@]}"
}

main() {
  [[ $# -gt 0 ]] || {
    usage
    exit 1
  }

  local command="$1"
  shift
  case "$command" in
    help | -h | --help) usage ;;
    list)
      [[ $# -eq 0 ]] || die "list does not accept arguments"
      cmd_list
      ;;
    base)
      if [[ ${EUID:-$(id -u)} -eq 0 ]] && ! dry_run_requested "$@"; then
        die "do not run Stow as root or with sudo"
      fi
      command -v stow > /dev/null 2>&1 || die "GNU Stow is required; run ./bootstrap.sh --packages-only first"
      cmd_base "$@"
      ;;
    *) die "unknown command: $command" ;;
  esac
}

main "$@"
