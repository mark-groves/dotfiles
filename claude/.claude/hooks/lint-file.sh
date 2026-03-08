#!/usr/bin/env bash
set -euo pipefail

# Dispatcher for Claude Code PostToolUse lint hooks.
# Reads hook JSON from stdin, extracts the file path, and routes
# to the appropriate linter script based on file type.

if ! command -v jq &>/dev/null; then
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]]; then
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASENAME="$(basename "$FILE_PATH")"

case "$BASENAME" in
  Dockerfile*)
    exec "$SCRIPT_DIR/lint-dockerfile.sh" "$FILE_PATH"
    ;;
esac

case "$FILE_PATH" in
  *.py)
    exec "$SCRIPT_DIR/lint-python.sh" "$FILE_PATH"
    ;;
  *.sh | *.bash)
    exec "$SCRIPT_DIR/lint-bash.sh" "$FILE_PATH"
    ;;
  *.md)
    exec "$SCRIPT_DIR/lint-markdown.sh" "$FILE_PATH"
    ;;
  *.yml | *.yaml)
    exec "$SCRIPT_DIR/lint-yaml.sh" "$FILE_PATH"
    ;;
  *.json)
    exec "$SCRIPT_DIR/lint-json.sh" "$FILE_PATH"
    ;;
  *.dockerfile)
    exec "$SCRIPT_DIR/lint-dockerfile.sh" "$FILE_PATH"
    ;;
esac

exit 0
