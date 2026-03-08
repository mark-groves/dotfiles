#!/usr/bin/env bash
set -euo pipefail
FILE="$1"

if ! command -v jq &>/dev/null; then
  exit 0
fi

OUTPUT=$(jq empty "$FILE" 2>&1) || {
  echo "JSON syntax error:" >&2
  echo "$OUTPUT" >&2
  exit 2
}
exit 0
