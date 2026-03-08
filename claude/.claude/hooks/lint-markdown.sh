#!/usr/bin/env bash
set -euo pipefail
FILE="$1"

if ! command -v markdownlint-cli2 &>/dev/null; then
  exit 0
fi

OUTPUT=$(markdownlint-cli2 "$FILE" 2>&1) || {
  echo "markdownlint issues:" >&2
  echo "$OUTPUT" >&2
  exit 2
}
exit 0
