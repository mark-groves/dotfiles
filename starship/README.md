# starship

Starship prompt configuration stow package. Stows to `~/.config/starship.toml`.

## Theme

Switch the active palette by changing one line in `starship.toml`:

```toml
palette = "tokyo_night"
```

Available palettes:

| Palette           |
|-------------------|
| `tokyo_night`     |
| `catppuccin_mocha`|
| `gruvbox_dark`    |
| `nord`            |
| `kanagawa`        |
| `rose_pine`       |
| `osaka_jade`      |

## Prompt format

Two-line prompt:

```text
╭─ <os> <user> <host> <shell>
│  <dir> <git branch> <git status> <git metrics> <cloud> <lang versions> <time>
╰─ <exit status> <jobs> <duration> <character>
```

A compact single-line variant is commented out in the config for use in narrow terminals.

## Modules enabled

- **OS / user / hostname** — hostname shown only over SSH
- **Shell indicator** — shows current shell name
- **Directory** — truncated to 3 path segments
- **Git** — branch, commit hash, state, status flags (`+` staged, `!` modified, `?` untracked, etc.), `+N/-N` metrics
- **Cloud** — AWS, GCloud, Kubernetes (auto-detected)
- **Languages** — Node, Python, Rust, Go, Java, Lua, C, and more (auto-detected)
- **Command duration** — shown after 800 ms
- **Exit status** — shown on non-zero exit
- **Jobs** — shown when background jobs are running
