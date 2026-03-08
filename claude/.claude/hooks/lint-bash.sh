#!/usr/bin/env bash
set -euo pipefail
FILE="$1"

if ! command -v shellcheck &>/dev/null; then
  exit 0
fi

OUTPUT=$(shellcheck -f gcc -S warning "$FILE" 2>&1) || {
  echo "shellcheck issues:" >&2
  echo "$OUTPUT" >&2
  exit 2
}
exit 0
