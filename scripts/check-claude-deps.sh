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
  echo "  ruff:              uv tool install ruff"
  echo "  shellcheck:        apt install shellcheck / brew install shellcheck"
  echo "  markdownlint-cli2: npm install -g markdownlint-cli2"
  echo "  yamllint:          uv tool install yamllint"
  echo "  jq:                apt install jq / brew install jq"
  echo "  hadolint:          brew install hadolint / download binary"
  exit 1
else
  echo "All linter dependencies installed."
fi
