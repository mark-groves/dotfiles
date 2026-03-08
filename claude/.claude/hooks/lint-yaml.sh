#!/usr/bin/env bash
set -euo pipefail
FILE="$1"

if ! command -v yamllint &>/dev/null; then
  exit 0
fi

OUTPUT=$(yamllint -d relaxed -f parsable "$FILE" 2>&1) || {
  echo "yamllint issues:" >&2
  echo "$OUTPUT" >&2
  exit 2
}
exit 0
