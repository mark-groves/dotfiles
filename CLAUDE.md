# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Stow-first dotfiles repo for Linux. GNU Stow symlinks config files from this repo into `$HOME`. See [AGENTS.md](AGENTS.md) for full conventions, code style, and rules.

## Commands

```bash
# Stow all base packages
./scripts/stow.sh base

# Stow host-specific overrides (auto-detects hostname)
./scripts/stow.sh host

# Dry-run (append -n to any command)
./scripts/stow.sh base -n

# Manual single-package dry-run
stow -n -v -t "$HOME" <package>

# Lint shell scripts
shellcheck scripts/stow.sh
```

There is no build system, test suite, or CI linting. Validate with dry-runs and shellcheck.

## Architecture

- **Base packages**: Top-level dirs (`git/`, `starship/`, etc.) — portable, no machine-specific settings. Contents mirror `$HOME` (e.g., `git/.config/git/config` -> `~/.config/git/config`).
- **Host overrides**: `hosts/<hostname>/<package>/` — hardware-specific config (monitors, input devices). Applied after base packages.
- **Scripts**: `scripts/` — management tooling, not stowed.
- **Stow ignore**: `.stow-global-ignore` excludes `.git`, `README.md`, and `scripts/` from stowing.

## Key Conventions

- **Always dry-run before stowing** (`stow -n -v`)
- **Commits**: Conventional Commits format — `<type>(<scope>): <summary>` (lowercase, <=72 chars)
- **Shell scripts**: `#!/usr/bin/env bash` + `set -euo pipefail`, `[[ ]]` conditionals, lowercase_underscore vars, always quoted
- **Hyprland configs**: Modular files, use `bindd` (not `bind`) for app bindings, host-specific hardware in `hosts/` only
- **New packages**: `mkdir -p <package>/.config/<app>`, dry-run, then stow

## Current Packages

| Package | Description |
|---------|-------------|
| `git` | Global git config (aliases, SSH signing via 1Password, rebase pull) |
| `starship` | Starship prompt with 7 color palettes (Tokyo Night default) |
| `hosts/nexus-unbound/hypr` | Hyprland overrides for dual-monitor HiDPI laptop |
