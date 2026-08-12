# Ubuntu packages sometimes ship different binary names than Fedora.
# Prefer a ~/.local/bin shim when the canonical name is missing.
if ! command -v fd > /dev/null 2>&1 && command -v fdfind > /dev/null 2>&1; then
  alias fd=fdfind
fi
if ! command -v bat > /dev/null 2>&1 && command -v batcat > /dev/null 2>&1; then
  alias bat=batcat
fi
