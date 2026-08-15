# Jump to directories with `z` / `zi` when zoxide is installed.
if [[ $- == *i* ]] && command -v zoxide > /dev/null 2>&1; then
  eval "$(zoxide init bash)"
fi
