# ~/.zshenv — always sourced (login, interactive, scripts).
# Sets ZDOTDIR so the real config lives in ~/.config/zsh (radley-style
# modular layout: .zshrc + aliases/bindings/fzf/plugins/prompt).

# ---------- XDG base directories ----------
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# ---------- ZDOTDIR ----------
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# ---------- Editor ----------
export EDITOR="nvim"
export VISUAL="nvim"

# ---------- Browser ----------
export BROWSER="zen-browser"

# ---------- Pager ----------
if command -v bat >/dev/null 2>&1; then
  export MANPAGER="bat -l man -p"
elif command -v batcat >/dev/null 2>&1; then
  export MANPAGER="batcat -l man -p"
fi

# ---------- GPG ----------
[[ -t 0 ]] && export GPG_TTY=$(tty)

# ---------- Starship ----------
export STARSHIP_CONFIG="$ZDOTDIR/starship.toml"

# ---------- PATH ----------
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"
