#!/usr/bin/env bash
set -euo pipefail
FILE="$1"

if ! command -v ruff &>/dev/null; then
  exit 0
fi

ERRORS=""

# Auto-fix safe issues; report unfixable ones
LINT_OUTPUT=$(ruff check --fix --output-format=concise "$FILE" 2>&1) || {
  ERRORS+="ruff lint issues:\n$LINT_OUTPUT\n"
}

# Report format issues without auto-applying (let Claude fix them)
FORMAT_OUTPUT=$(ruff format --check --diff "$FILE" 2>&1) || {
  ERRORS+="ruff format issues:\n$FORMAT_OUTPUT\n"
}

if [[ -n "$ERRORS" ]]; then
  echo -e "$ERRORS" >&2
  exit 2
fi
exit 0
