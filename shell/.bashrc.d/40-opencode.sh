# OpenCode installs its CLI outside the usual user bin directories.
case ":$PATH:" in
  *":$HOME/.opencode/bin:"*) ;;
  *) PATH="$HOME/.opencode/bin${PATH:+:$PATH}" ;;
esac
export PATH
