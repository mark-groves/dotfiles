#!/usr/bin/env bash
set -euo pipefail
FILE="$1"

if ! command -v hadolint &>/dev/null; then
  exit 0
fi

OUTPUT=$(hadolint "$FILE" 2>&1) || {
  echo "hadolint issues:" >&2
  echo "$OUTPUT" >&2
  exit 2
}
exit 0
