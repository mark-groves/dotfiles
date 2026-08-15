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
  starship      Prompt binary (pinned GitHub release; overlays older distro packages)
  uv            Astral uv (Ubuntu fallback; Fedora prefers dnf)
  herdr         Agent multiplexer (GitHub release binary)
  codex         OpenAI Codex CLI (GitHub musl release)
  cursor-cli    Cursor Agent CLI (`agent`; official installer)
  actionlint    GitHub Actions linter
  ruff          Python linter/formatter
  zizmor        GitHub Actions security scanner
  yq            mikefarah/yq (not the Ubuntu kislyuk wrapper)
  rust-analyzer rustup component, or GitHub binary without rustup
  ubuntu-shims  fd/bat name compatibility links for Debian packaging

Starship and uv fallbacks download a pinned GitHub tarball and verify sha256.
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
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH" ;;
  esac
}

host_arch() {
  case "$(uname -m)" in
    x86_64 | amd64) printf 'amd64\n' ;;
    aarch64 | arm64) printf 'arm64\n' ;;
    *) die "unsupported architecture: $(uname -m)" ;;
  esac
}

# Bump the release tag and both architecture checksums together.
STARSHIP_RELEASE='1.26.0'
UV_RELEASE='0.12.5'

# True when $1 is a semantic version greater than or equal to $2.
semver_ge() {
  local left="$1" right="$2"
  [[ -n "$left" && -n "$right" ]] || return 1
  [[ "$(printf '%s\n%s\n' "$left" "$right" | sort -V | tail -n1)" == "$left" ]]
}

current_starship_version() {
  local raw
  command -v starship > /dev/null 2>&1 || return 1
  raw="$(starship --version 2> /dev/null | awk 'NR == 1 { print $2 }')"
  [[ -n "$raw" ]] || return 1
  printf '%s\n' "$raw"
}

verify_sha256() {
  local file="$1" expected="$2" actual
  need_cmd sha256sum
  actual="$(sha256sum -- "$file")" || die "failed to hash $file"
  actual="${actual%% *}"
  [[ "$actual" == "$expected" ]] ||
    die "checksum mismatch for $(basename "$file"): expected $expected, got $actual"
}

download_verified_tarball() {
  local url="$1" sha256="$2" dest_dir="$3"
  need_cmd curl
  need_cmd tar
  curl -fsSL "$url" -o "$dest_dir/asset.tar.gz"
  verify_sha256 "$dest_dir/asset.tar.gz" "$sha256"
  tar -xzf "$dest_dir/asset.tar.gz" -C "$dest_dir"
}

install_starship() {
  local arch target sha256 url tmp current
  ensure_local_bin
  if current="$(current_starship_version)" && semver_ge "$current" "$STARSHIP_RELEASE"; then
    printf 'starship %s already available: %s\n' "$current" "$(command -v starship)"
    return
  fi
  if [[ -n "${current:-}" ]]; then
    printf 'Upgrading starship %s -> %s\n' "$current" "$STARSHIP_RELEASE"
  fi
  arch="$(host_arch)"
  case "$arch" in
    amd64)
      target='x86_64-unknown-linux-musl'
      sha256='b7c232b0e8249d8e55a40beb79c5c43a7d370f3f9408bd215deb0170daeaadf3'
      ;;
    arm64)
      target='aarch64-unknown-linux-musl'
      sha256='dc30189378d2f2e287384e8a692d3f95ad1df64cf0e8c36aa9201516028aed6b'
      ;;
    *) die "unsupported architecture for starship: $arch" ;;
  esac
  url="https://github.com/starship/starship/releases/download/v${STARSHIP_RELEASE}/starship-${target}.tar.gz"
  tmp="$(mktemp -d)"
  # Expand now: locals are unset when the RETURN trap runs under set -u.
  # shellcheck disable=SC2064
  trap "rm -rf $(printf '%q' "$tmp")" RETURN
  download_verified_tarball "$url" "$sha256" "$tmp"
  install -m 0755 "$tmp/starship" "$HOME/.local/bin/starship"
  printf 'Installed starship %s to %s\n' "$STARSHIP_RELEASE" "$HOME/.local/bin/starship"
}

install_uv() {
  local arch target sha256 url tmp
  if command -v uv > /dev/null 2>&1; then
    printf 'uv already available: %s\n' "$(command -v uv)"
    return
  fi
  ensure_local_bin
  arch="$(host_arch)"
  case "$arch" in
    amd64)
      target='x86_64-unknown-linux-gnu'
      sha256='68a509da24b06b4223a1c0175fb5eb5bc79342b76cbeff0cfe51ac3f5b17b6b2'
      ;;
    arm64)
      target='aarch64-unknown-linux-gnu'
      sha256='9bf43b4d1a07665bf64d4c4e710930b382321a785e0eb10aac07f46471f86a31'
      ;;
    *) die "unsupported architecture for uv: $arch" ;;
  esac
  url="https://github.com/astral-sh/uv/releases/download/${UV_RELEASE}/uv-${target}.tar.gz"
  tmp="$(mktemp -d)"
  # Expand now: locals are unset when the RETURN trap runs under set -u.
  # shellcheck disable=SC2064
  trap "rm -rf $(printf '%q' "$tmp")" RETURN
  download_verified_tarball "$url" "$sha256" "$tmp"
  install -m 0755 "$tmp/uv-${target}/uv" "$HOME/.local/bin/uv"
  install -m 0755 "$tmp/uv-${target}/uvx" "$HOME/.local/bin/uvx"
  printf 'Installed uv %s to %s\n' "$UV_RELEASE" "$HOME/.local/bin/uv"
}

install_github_release_binary() {
  local tool="$1" repo="$2" asset_glob="$3" archive_bin="${4:-}" force="${5:-}"
  local arch uname_m url tmp

  if [[ "$force" != "--force" ]] && command -v "$tool" > /dev/null 2>&1; then
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
  # Expand now: locals are unset when the RETURN trap runs under set -u.
  # shellcheck disable=SC2064
  trap "rm -rf $(printf '%q' "$tmp")" RETURN
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
    *.gz)
      need_cmd gzip
      gzip -dc "$tmp/asset" > "$tmp/$tool"
      install -m 0755 "$tmp/$tool" "$HOME/.local/bin/$tool"
      ;;
    *)
      install -m 0755 "$tmp/asset" "$HOME/.local/bin/$tool"
      ;;
  esac
  printf 'Installed %s to %s\n' "$tool" "$HOME/.local/bin/$tool"
}

install_actionlint() {
  local arch asset_glob
  arch="$(host_arch)"
  asset_glob="actionlint_.*_linux_${arch}\\.tar\\.gz$"
  install_github_release_binary actionlint rhysd/actionlint "$asset_glob" actionlint
}

install_ruff() {
  local arch target asset_glob
  if command -v ruff > /dev/null 2>&1; then
    printf 'ruff already available: %s\n' "$(command -v ruff)"
    return
  fi
  if command -v uv > /dev/null 2>&1; then
    uv tool install ruff
    return
  fi
  arch="$(host_arch)"
  case "$arch" in
    amd64) target='x86_64-unknown-linux-gnu' ;;
    arm64) target='aarch64-unknown-linux-gnu' ;;
    *) die "unsupported architecture for ruff: $arch" ;;
  esac
  asset_glob="ruff-${target}\\.tar\\.gz$"
  install_github_release_binary ruff astral-sh/ruff \
    "$asset_glob" "ruff-${target}/ruff"
}

install_zizmor() {
  if command -v zizmor > /dev/null 2>&1; then
    printf 'zizmor already available: %s\n' "$(command -v zizmor)"
    return
  fi
  if ! command -v uv > /dev/null 2>&1; then
    install_uv
  fi
  if command -v uv > /dev/null 2>&1; then
    uv tool install zizmor
    return
  fi
  die "zizmor install needs uv, or install the binary manually into ~/.local/bin"
}

install_yq() {
  local arch force=''
  if command -v yq > /dev/null 2>&1; then
    if yq --version 2> /dev/null | grep -qi mikefarah; then
      printf 'mikefarah yq already available: %s\n' "$(command -v yq)"
      return
    fi
    printf 'Warning: existing yq is not mikefarah/yq; installing alongside in ~/.local/bin\n' >&2
    force='--force'
  fi
  arch="$(host_arch)"
  install_github_release_binary yq mikefarah/yq "yq_linux_${arch}$" '' "$force"
}

install_rust_analyzer() {
  local arch target asset_glob
  if command -v rust-analyzer > /dev/null 2>&1; then
    printf 'rust-analyzer already available: %s\n' "$(command -v rust-analyzer)"
    return
  fi
  if command -v rustup > /dev/null 2>&1; then
    rustup component add rust-analyzer
    return
  fi

  # Ubuntu apt ships rustc/cargo without rustup; fall back to the release binary.
  arch="$(host_arch)"
  case "$arch" in
    amd64) target='x86_64-unknown-linux-gnu' ;;
    arm64) target='aarch64-unknown-linux-gnu' ;;
    *) die "unsupported architecture for rust-analyzer: $arch" ;;
  esac
  asset_glob="rust-analyzer-${target}\\.gz$"
  install_github_release_binary rust-analyzer rust-lang/rust-analyzer "$asset_glob"
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

install_herdr() {
  local arch asset_glob
  if command -v herdr > /dev/null 2>&1; then
    printf 'herdr already available: %s\n' "$(command -v herdr)"
    return
  fi
  arch="$(host_arch)"
  case "$arch" in
    amd64) asset_glob='^herdr-linux-x86_64$' ;;
    arm64) asset_glob='^herdr-linux-aarch64$' ;;
    *) die "unsupported architecture for herdr: $arch" ;;
  esac
  install_github_release_binary herdr herdrdev/herdr "$asset_glob"
}

install_codex() {
  local arch target
  if command -v codex > /dev/null 2>&1; then
    printf 'codex already available: %s\n' "$(command -v codex)"
    return
  fi
  arch="$(host_arch)"
  case "$arch" in
    amd64) target='x86_64-unknown-linux-musl' ;;
    arm64) target='aarch64-unknown-linux-musl' ;;
    *) die "unsupported architecture for codex: $arch" ;;
  esac
  install_github_release_binary codex openai/codex \
    "^codex-${target}\\.tar\\.gz$" "codex-${target}"
}

install_cursor_cli() {
  if command -v agent > /dev/null 2>&1; then
    printf 'cursor CLI already available: %s\n' "$(command -v agent)"
    return
  fi
  need_cmd curl
  ensure_local_bin
  curl -fsS https://cursor.com/install | bash
}

install_one() {
  case "$1" in
    starship) install_starship ;;
    uv) install_uv ;;
    herdr) install_herdr ;;
    codex) install_codex ;;
    cursor-cli) install_cursor_cli ;;
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
  ensure_local_bin
  local tool
  for tool in "${tools[@]}"; do
    install_one "$tool"
  done
}

main "$@"
