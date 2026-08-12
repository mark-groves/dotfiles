# Git configuration

Ordinary commits are unsigned so unattended tools do not need access to a
personal signing key. Use `git cis` (an alias for `git commit -S`) when
intentionally creating a signed commit. Git uses the platform SSH signer and
the key exposed by the user's SSH agent, including 1Password's SSH agent.

Authentication is separate from signing. HTTPS GitHub credentials are supplied
by `gh auth git-credential` through `~/.local/bin/gh-credential`; no token is
stored in this repository.
