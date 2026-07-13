# Git configuration

Ordinary commits are unsigned so unattended tools do not need access to a
personal signing key. Use `git cis` (an alias for `git commit -S`) when
intentionally creating a signed commit through 1Password.

Authentication is separate from signing. HTTPS GitHub credentials are supplied
by `gh auth git-credential`; no token is stored in this repository.
