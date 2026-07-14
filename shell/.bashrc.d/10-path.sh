# Make user-installed development tools available without installer-managed
# edits to shell startup files.
for user_bin in "$HOME/.cargo/bin" "$HOME/.local/bin"; do
  case ":$PATH:" in
    *":$user_bin:"*) ;;
    *) PATH="$user_bin${PATH:+:$PATH}" ;;
  esac
done
unset user_bin
export PATH
