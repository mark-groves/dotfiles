# tmux

Tmux configuration stow package. Stows to `~/.config/tmux/tmux.conf`.

## Prefix

| Key          | Role             |
| ------------ | ---------------- |
| `Ctrl+Space` | Primary prefix   |
| `Ctrl+b`     | Secondary prefix |

## Keybindings

### Panes

| Key                      | Action                |
| ------------------------ | --------------------- |
| `Prefix + h`             | Split horizontally    |
| `Prefix + v`             | Split vertically      |
| `Prefix + x`             | Kill pane             |
| `Ctrl+Alt+←/→/↑/↓`       | Move between panes    |
| `Ctrl+Alt+Shift+←/→/↑/↓` | Resize pane (5 cells) |

### Windows

| Key               | Action                       |
| ----------------- | ---------------------------- |
| `Prefix + c`      | New window (at current path) |
| `Prefix + k`      | Kill window                  |
| `Prefix + r`      | Rename window                |
| `Alt+1` … `Alt+9` | Jump to window by number     |
| `Alt+←/→`         | Previous / next window       |

### Sessions

| Key          | Action                        |
| ------------ | ----------------------------- |
| `Prefix + C` | New session (at current path) |
| `Prefix + K` | Kill session                  |
| `Prefix + R` | Rename session                |
| `Prefix + P` | Previous session              |
| `Prefix + N` | Next session                  |
| `Alt+↑/↓`    | Previous / next session       |

### Copy mode (vi)

| Key | Action                  |
| --- | ----------------------- |
| `v` | Begin selection         |
| `y` | Copy selection and exit |

### Other

| Key          | Action        |
| ------------ | ------------- |
| `Prefix + q` | Reload config |

## Notable settings

- `base-index 1` / `pane-base-index 1` — windows and panes numbered from 1
- `mouse on` — mouse support enabled
- `history-limit 50000` — large scrollback buffer
- `escape-time 0` — no delay for escape sequences (important for Neovim)
- `focus-events on` — passes focus events to applications
- `set-clipboard on` / `allow-passthrough on` — system clipboard integration
- `detach-on-destroy off` — switches to another session instead of exiting when a session is killed
- `renumber-windows on` — windows renumbered automatically after one is closed
