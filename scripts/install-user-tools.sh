#!/usr/bin/env bash
set -euo pipefail

# Install user-space CLI tools that this workstation keeps in ~/.local/bin
# (or via rustup) rather than the OS package manager.

usage() {
  cat << 'EOF'
Usage: install-user-tools.sh [tool ...]

Install selected user-space tools into ~/.local/bin (and rust-analyzer via
rustup when needed). With no arguments, installs the default migration set:
  starship uv actionlint ruff zizmor yq rust-analyzer ubuntu-shims

Tools:
  starship      Prompt binary (Fedora fallback; Ubuntu prefers apt)
  uv            Astral uv (Ubuntu fallback; Fedora prefers dnf)
  actionlint    GitHub Actions linter
  ruff          Python linter/formatter
  zizmor        GitHub Actions security scanner
  yq            mikefarah/yq (not the Ubuntu kislyuk wrapper)
  rust-analyzer rustup component
  ubuntu-shims  fd/bat name compatibility links for Debian packaging
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" > /dev/null 2>&1 || die "required command not found: $1"
}

ensure_local_bin() {
  mkdir -p "$HOME/.local/bin"
}

install_starship() {
  if command -v starship > /dev/null 2>&1; then
    printf 'starship already available: %s\n' "$(command -v starship)"
    return
  fi
  need_cmd curl
  ensure_local_bin
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
}

install_uv() {
  if command -v uv > /dev/null 2>&1; then
    printf 'uv already available: %s\n' "$(command -v uv)"
    return
  fi
  need_cmd curl
  ensure_local_bin
  curl -fsSL https://astral.sh/uv/install.sh | sh
}

install_github_release_binary() {
  local tool="$1" repo="$2" asset_glob="$3" archive_bin="${4:-}"
  local arch uname_m url tmp

  if command -v "$tool" > /dev/null 2>&1; then
    printf '%s already available: %s\n' "$tool" "$(command -v "$tool")"
    return
  fi

  need_cmd curl
  need_cmd tar
  need_cmd jq
  ensure_local_bin
  uname_m="$(uname -m)"
  case "$uname_m" in
    x86_64 | amd64) arch='amd64|x86_64|x86-64' ;;
    aarch64 | arm64) arch='arm64|aarch64' ;;
    *) die "unsupported architecture for $tool: $uname_m" ;;
  esac

  url="$(
    curl -fsSL "https://api.github.com/repos/$repo/releases/latest" |
      jq -r --arg re "$asset_glob" --arg arch "$arch" '
        .assets[]
        | select(.name | test($re))
        | select(.name | test($arch; "i"))
        | .browser_download_url
      ' | head -n 1
  )"
  [[ -n "$url" && "$url" != null ]] || die "could not locate a $tool release asset"

  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  curl -fsSL "$url" -o "$tmp/asset"

  case "$url" in
    *.tar.gz | *.tgz)
      tar -xzf "$tmp/asset" -C "$tmp"
      if [[ -n "$archive_bin" ]]; then
        install -m 0755 "$tmp/$archive_bin" "$HOME/.local/bin/$tool"
      else
        install -m 0755 "$(find "$tmp" -type f -name "$tool" | head -n 1)" \
          "$HOME/.local/bin/$tool"
      fi
      ;;
    *)
      install -m 0755 "$tmp/asset" "$HOME/.local/bin/$tool"
      ;;
  esac
  printf 'Installed %s to %s\n' "$tool" "$HOME/.local/bin/$tool"
}

install_actionlint() {
  install_github_release_binary actionlint rhysd/actionlint \
    'actionlint_.*_linux_amd64\\.tar\\.gz$' actionlint
}

install_ruff() {
  if command -v ruff > /dev/null 2>&1; then
    printf 'ruff already available: %s\n' "$(command -v ruff)"
    return
  fi
  if command -v uv > /dev/null 2>&1; then
    uv tool install ruff
    return
  fi
  install_github_release_binary ruff astral-sh/ruff \
    'ruff-x86_64-unknown-linux-gnu\\.tar\\.gz$' ruff-x86_64-unknown-linux-gnu/ruff
}

install_zizmor() {
  if command -v zizmor > /dev/null 2>&1; then
    printf 'zizmor already available: %s\n' "$(command -v zizmor)"
    return
  fi
  if command -v uv > /dev/null 2>&1; then
    uv tool install zizmor
    return
  fi
  die "zizmor install needs uv, or install the binary manually into ~/.local/bin"
}

install_yq() {
  if command -v yq > /dev/null 2>&1; then
    if yq --version 2> /dev/null | grep -qi mikefarah; then
      printf 'mikefarah yq already available: %s\n' "$(command -v yq)"
      return
    fi
    printf 'Warning: existing yq is not mikefarah/yq; installing alongside in ~/.local/bin\n' >&2
  fi
  install_github_release_binary yq mikefarah/yq 'yq_linux_amd64$'
}

install_rust_analyzer() {
  if command -v rust-analyzer > /dev/null 2>&1; then
    printf 'rust-analyzer already available: %s\n' "$(command -v rust-analyzer)"
    return
  fi
  need_cmd rustup
  rustup component add rust-analyzer
}

install_ubuntu_shims() {
  ensure_local_bin
  if ! command -v fd > /dev/null 2>&1 && command -v fdfind > /dev/null 2>&1; then
    ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
    printf 'Linked fd -> %s\n' "$(command -v fdfind)"
  fi
  if ! command -v bat > /dev/null 2>&1 && command -v batcat > /dev/null 2>&1; then
    ln -s "$(command -v batcat)" "$HOME/.local/bin/bat"
    printf 'Linked bat -> %s\n' "$(command -v batcat)"
  fi
}

install_one() {
  case "$1" in
    starship) install_starship ;;
    uv) install_uv ;;
    actionlint) install_actionlint ;;
    ruff) install_ruff ;;
    zizmor) install_zizmor ;;
    yq) install_yq ;;
    rust-analyzer) install_rust_analyzer ;;
    ubuntu-shims) install_ubuntu_shims ;;
    *) die "unknown user tool: $1" ;;
  esac
}

main() {
  local -a tools=("$@")
  if [[ ${#tools[@]} -eq 0 ]]; then
    tools=(starship uv actionlint ruff zizmor yq rust-analyzer ubuntu-shims)
  fi
  [[ ${EUID:-$(id -u)} -ne 0 ]] || die "run as your normal user, not root"
  local tool
  for tool in "${tools[@]}"; do
    install_one "$tool"
  done
}

main "$@"
