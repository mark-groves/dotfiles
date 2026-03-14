# check-claude-deps.sh

Checks whether linter dependencies required by the `claude` hooks package are installed.

## Usage

```sh
./scripts/check-claude-deps.sh
```

## Checked tools

`ruff`, `shellcheck`, `markdownlint-cli2`, `yamllint`, `jq`, `hadolint`

## Behavior

- Exits `0` if all tools are found.
- Exits non-zero and prints install suggestions if any are missing.
