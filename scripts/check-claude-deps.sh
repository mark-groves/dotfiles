#!/usr/bin/env bash
# Check for linter dependencies used by the claude hooks package.
set -euo pipefail

TOOLS=(ruff shellcheck markdownlint-cli2 yamllint jq hadolint)
MISSING=()

for tool in "${TOOLS[@]}"; do
  if ! command -v "$tool" &>/dev/null; then
    MISSING+=("$tool")
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "Missing linter dependencies:"
  for dep in "${MISSING[@]}"; do
    echo "  - $dep"
  done
  echo ""
  echo "Install suggestions:"
  declare -A INSTALL_HINTS=(
    [ruff]="uv tool install ruff"
    [shellcheck]="apt install shellcheck / brew install shellcheck"
    [markdownlint-cli2]="npm install -g markdownlint-cli2"
    [yamllint]="uv tool install yamllint"
    [jq]="apt install jq / brew install jq"
    [hadolint]="brew install hadolint / download binary"
  )
  for dep in "${MISSING[@]}"; do
    echo "  $dep: ${INSTALL_HINTS[$dep]}"
  done
  exit 1
else
  echo "All linter dependencies installed."
fi
