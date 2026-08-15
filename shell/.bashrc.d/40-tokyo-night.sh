# Tokyo Night colors for CLI tools. Follows the desktop light/dark setting
# (same split Ghostty uses: Night vs Day). Wrappers for btop/lazygit/delta
# re-read the desktop at launch so Herdr popups match too.

if [[ -z "${TOKYO_NIGHT_FZF_BASE+x}" ]]; then
  TOKYO_NIGHT_FZF_BASE="${FZF_DEFAULT_OPTS-}"
fi

tokyo_night_fzf_colors() {
  if [[ "$1" == day ]]; then
    printf '%s' "\
--color=bg+:#b7c1e3 \
--color=bg:#d0d5e3 \
--color=border:#4094a3 \
--color=fg:#3760bf \
--color=gutter:#d0d5e3 \
--color=header:#b15c00 \
--color=hl+:#188092 \
--color=hl:#188092 \
--color=info:#8990b3 \
--color=marker:#d20065 \
--color=pointer:#d20065 \
--color=prompt:#188092 \
--color=query:#3760bf:regular \
--color=scrollbar:#4094a3 \
--color=separator:#b15c00 \
--color=spinner:#d20065"
  else
    printf '%s' "\
--color=bg+:#283457 \
--color=bg:#16161e \
--color=border:#27a1b9 \
--color=fg:#c0caf5 \
--color=gutter:#16161e \
--color=header:#ff9e64 \
--color=hl+:#2ac3de \
--color=hl:#2ac3de \
--color=info:#545c7e \
--color=marker:#ff007c \
--color=pointer:#ff007c \
--color=prompt:#2ac3de \
--color=query:#c0caf5:regular \
--color=scrollbar:#27a1b9 \
--color=separator:#ff9e64 \
--color=spinner:#ff007c"
  fi
}

tokyo_night_starship() {
  local style="$1" src dest palette
  src="${HOME}/.config/starship.toml"
  dest="${XDG_CACHE_HOME:-$HOME/.cache}/starship-tokyo-night.toml"
  [[ -r "$src" ]] || return 0
  palette="tokyo_night"
  [[ "$style" == day ]] && palette="tokyo_night_day"
  mkdir -p "$(dirname "$dest")"
  sed "s/^palette = \".*\"/palette = \"${palette}\"/" "$src" > "$dest"
  export STARSHIP_CONFIG="$dest"
}

tokyo_night_apply() {
  local style="$1"
  export TOKYO_NIGHT_STYLE="$style"
  if [[ "$style" == day ]]; then
    export BAT_THEME="tokyonight_day"
    export EZA_CONFIG_DIR="${HOME}/.config/eza/day"
  else
    export BAT_THEME="tokyonight_night"
    export EZA_CONFIG_DIR="${HOME}/.config/eza/night"
  fi
  local fzf_opts
  fzf_opts="${TOKYO_NIGHT_FZF_BASE:+${TOKYO_NIGHT_FZF_BASE} }$(tokyo_night_fzf_colors "$style")"
  export FZF_DEFAULT_OPTS="$fzf_opts"
  tokyo_night_starship "$style"
}

tokyo_night_refresh() {
  local style="night"
  if command -v tokyo-night-style > /dev/null 2>&1; then
    style="$(tokyo-night-style)"
  fi
  [[ "${TOKYO_NIGHT_STYLE:-}" == "$style" ]] && return 0
  tokyo_night_apply "$style"
}

tokyo_night_refresh

if [[ $- == *i* ]]; then
  case ";${PROMPT_COMMAND-};" in
    *tokyo_night_refresh*) ;;
    *) PROMPT_COMMAND="tokyo_night_refresh${PROMPT_COMMAND:+;${PROMPT_COMMAND}}" ;;
  esac
fi
