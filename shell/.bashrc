# Portable Bash startup. Keep machine-specific commands in ~/.bashrc.d instead.
if [[ -r /etc/bashrc ]]; then
  # shellcheck source=/dev/null
  . /etc/bashrc
fi

for rc in "$HOME"/.bashrc.d/*.sh; do
  # shellcheck disable=SC1090
  [[ -r "$rc" ]] && . "$rc"
done
unset rc
