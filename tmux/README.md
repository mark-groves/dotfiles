# tmux

Tmux configuration stow package. Stows to `~/.config/tmux/tmux.conf`.

## Prefix

| Key        | Role               |
|------------|--------------------|
| `C-Space`  | Primary prefix     |
| `C-b`      | Secondary prefix   |

## Keybindings

### Panes

| Key              | Action                          |
|------------------|---------------------------------|
| `prefix h`       | Split horizontally              |
| `prefix v`       | Split vertically                |
| `prefix x`       | Kill pane                       |
| `C-M-←/→/↑/↓`   | Move between panes              |
| `C-M-S-←/→/↑/↓` | Resize pane (5 cells)           |

### Windows

| Key          | Action                          |
|--------------|---------------------------------|
| `prefix c`   | New window (at current path)    |
| `prefix k`   | Kill window                     |
| `prefix r`   | Rename window                   |
| `M-1` … `M-9`| Jump to window by number        |
| `M-←/→`      | Previous / next window          |

### Sessions

| Key        | Action                          |
|------------|---------------------------------|
| `prefix C` | New session (at current path)   |
| `prefix K` | Kill session                    |
| `prefix R` | Rename session                  |
| `prefix P` | Previous session                |
| `prefix N` | Next session                    |
| `M-↑/↓`    | Previous / next session         |

### Copy mode (vi)

| Key | Action                        |
|-----|-------------------------------|
| `v` | Begin selection               |
| `y` | Copy selection and exit       |

### Other

| Key        | Action                        |
|------------|-------------------------------|
| `prefix q` | Reload config                 |

## Notable settings

- `base-index 1` / `pane-base-index 1` — windows and panes numbered from 1
- `mouse on` — mouse support enabled
- `history-limit 50000` — large scrollback buffer
- `escape-time 0` — no delay for escape sequences (important for Neovim)
- `focus-events on` — passes focus events to applications
- `set-clipboard on` / `allow-passthrough on` — system clipboard integration
- `detach-on-destroy off` — switches to another session instead of exiting when a session is killed
- `renumber-windows on` — windows renumbered automatically after one is closed
