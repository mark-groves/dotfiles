# Load approved per-project environments when entering their directories.
if [[ $- == *i* ]] && command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook bash)"
fi
