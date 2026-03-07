# git

Git configuration stow package. Stows to `~/.config/git/config`.

## Aliases

| Alias | Command    |
|-------|------------|
| `co`  | `checkout` |
| `sw`  | `switch`   |
| `br`  | `branch`   |
| `ci`  | `commit`   |
| `st`  | `status`   |

## Key settings

| Area   | Setting                     | Effect                                                     |
|--------|-----------------------------|-------------------------------------------------------------|
| init   | `defaultBranch = main`      | New repos start on `main`                                   |
| pull   | `rebase = true`             | Rebase instead of merge on pull                             |
| push   | `autoSetupRemote`           | Automatically sets upstream branch on first push            |
| push   | `followTags`                | Pushes annotated tags that point to pushed commits          |
| fetch  | `prune = true`              | Removes stale remote-tracking branches on fetch             |
| fetch  | `pruneTags = true`          | Removes deleted remote tags on fetch                        |
| diff   | `algorithm = histogram`     | Clearer diffs on moved/edited lines                         |
| diff   | `colorMoved = plain`        | Highlights moved blocks in diffs                            |
| commit | `verbose = true`            | Includes diff in commit message editor                      |
| commit | `gpgsign = true`            | Signs all commits with SSH key via 1Password                |
| branch | `sort = -committerdate`     | Branch list sorted by most recent activity                  |
| tag    | `sort = -version:refname`   | Tags sorted by semantic version                             |
| rerere | `enabled + autoupdate`      | Records and auto-replays conflict resolutions               |

## Signing

Commits are signed with an SSH key (`ssh-ed25519`) via 1Password's SSH agent (`op-ssh-sign`).
