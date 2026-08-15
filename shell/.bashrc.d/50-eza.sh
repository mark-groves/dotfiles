# Use eza in place of ls when it is installed. These run after Ubuntu's
# default ls aliases because ~/.bashrc.d is sourced last.
if command -v eza > /dev/null 2>&1; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -l --group-directories-first --git --icons=auto'
  alias la='eza -la --group-directories-first --git --icons=auto'
  alias l='eza --group-directories-first --icons=auto'
  alias lt='eza --tree --level=2 --group-directories-first --icons=auto'
fi
