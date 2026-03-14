# hosts/nexus-unbound

Machine-specific stow overrides for `nexus-unbound`.

These packages are applied after base packages so hardware- and host-specific
settings can safely override portable defaults.

## Current host packages

- `hypr` -> `~/.config/hypr/*` overrides for this machine

## Apply / refresh

Always dry-run first:

```bash
./scripts/stow.sh base -n
./scripts/stow.sh host nexus-unbound -n
```

Then apply:

```bash
./scripts/stow.sh base
./scripts/stow.sh host nexus-unbound
```

If running on this host, you can omit the hostname:

```bash
./scripts/stow.sh host
```

## Hyprland profile for this host

This host currently assumes a dual-monitor setup:

- Internal display: `eDP-2`, scale `2` (HiDPI)
- External display: `DP-3` (LG Ultrawide), scale `1`, positioned above and offset left of internal
- Mixed-DPI GTK scaling: `GDK_SCALE=1`

See monitor config in:

- `hosts/nexus-unbound/hypr/.config/hypr/monitors.conf`

Workspace mapping is monitor-specific:

- Workspaces `1-6` on `DP-3` (primary/default on workspace 1)
- Workspaces `7-9` on `eDP-2`

See:

- `hosts/nexus-unbound/hypr/.config/hypr/workspaces.conf`

## Custom keybindings

Defined in `hosts/nexus-unbound/hypr/.config/hypr/bindings.conf`. These extend and override Omarchy's defaults.

### Applications

| Binding                | Action                                      |
|------------------------|---------------------------------------------|
| `SUPER RETURN`         | New terminal (at current terminal's cwd)    |
| `SUPER ALT RETURN`     | New tmux session in terminal                |
| `SUPER SHIFT RETURN`   | Launch browser                              |
| `SUPER SHIFT F`        | Open file manager                           |
| `SUPER ALT SHIFT F`    | Open file manager at current terminal's cwd |
| `SUPER SHIFT B`        | Launch browser                              |
| `SUPER SHIFT ALT B`    | Launch browser (private mode)               |
| `SUPER SHIFT M`        | Spotify                                     |
| `SUPER SHIFT N`        | Editor                                      |
| `SUPER SHIFT T`        | btop (activity monitor)                     |
| `SUPER SHIFT D`        | lazydocker                                  |
| `SUPER SHIFT S`        | Signal                                      |
| `SUPER SHIFT O`        | Obsidian                                    |
| `SUPER SHIFT W`        | Typora                                      |
| `SUPER SHIFT /`        | 1Password                                   |

### Web apps

| Binding                | Web app           |
|------------------------|-------------------|
| `SUPER SHIFT A`        | Claude            |
| `SUPER SHIFT ALT A`    | Claude Code       |
| `SUPER SHIFT C`        | Proton Calendar   |
| `SUPER SHIFT E`        | Proton Mail       |
| `SUPER SHIFT Y`        | YouTube           |
| `SUPER SHIFT ALT G`    | ChatGPT           |
| `SUPER SHIFT CTRL G`   | Google Messages   |
| `SUPER SHIFT P`        | Google Photos     |
| `SUPER SHIFT X`        | X (Twitter)       |
| `SUPER SHIFT ALT X`    | X — new post      |
| `SUPER SHIFT G`        | GitHub            |

### Workspace / monitor

| Binding                    | Action                              |
|----------------------------|-------------------------------------|
| `SUPER SHIFT ALT UP`       | Move workspace to monitor above     |
| `SUPER SHIFT ALT DOWN`     | Move workspace to monitor below     |

## Notes for future edits

- Keep hardware-specific settings in this host package, not base packages.
- Keep portable defaults in base; use this directory only for overrides.
- Do not edit Omarchy defaults under
  `~/.local/share/omarchy/default/...`; override via files in
  `~/.config/hypr/` instead.
- If monitor identifiers change, run `hyprctl monitors` and update
  `monitors.conf` and `workspaces.conf` together.

## Troubleshooting

- Check for stow conflicts before applying:
  `stow -n -v -t "$HOME" -d hosts/nexus-unbound hypr`
- If host package discovery fails, ensure package directories contain real files
  (not only empty subdirectories).
