# Portable Bash startup. Keep machine-specific commands in ~/.bashrc.d instead.
if [[ -r /etc/bashrc ]]; then
  # shellcheck source=/dev/null
  . /etc/bashrc
fi

for rc in "$HOME"/.bashrc.d/*.sh; do
  if [[ -r "$rc" ]]; then
    # shellcheck disable=SC1090
    . "$rc"
  fi
done
unset rc
