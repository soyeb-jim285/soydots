# Powerful but minimal zsh configuration — radley-style base (radleylewis/zsh)
# with local customizations. See ~/.config/zsh/{aliases,bindings,fzf,plugins,prompt}.zsh
#
# Uses:
#   Plugins:      fast-syntax-highlighting, zsh-autosuggestions,
#                 zsh-history-substring-search, zsh-vi-mode
#   Prompt:       starship
#   Navigation:   zoxide, fzf, fd
#   CLI tools:    eza, bat, nvim, ripgrep

# =========================================================
# Required runtime directories (self-heal so a fresh box just works)
# =========================================================

[[ -d "$XDG_STATE_HOME/zsh" ]] || mkdir -p "$XDG_STATE_HOME/zsh"
[[ -d "$XDG_CACHE_HOME/zsh" ]] || mkdir -p "$XDG_CACHE_HOME/zsh"

# =========================================================
# History
# =========================================================

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS

# =========================================================
# Shell behaviour
# =========================================================

setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT       # sort file10 after file9, not after file1
setopt INTERACTIVE_COMMENTS    # allow # comments at the interactive prompt
setopt GLOB_DOTS               # include dotfiles in globbing

# =========================================================
# lf icons (guarded — lf is optional)
# =========================================================

[[ -f ~/.config/lf/icons ]] && export LF_ICONS=$(tr '\n' ':' < ~/.config/lf/icons)

# =========================================================
# Completion
# =========================================================

# Load completion system
autoload -Uz compinit

# Initialize completion with cached metadata file
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

# Enable interactive completion menu selection
zstyle ':completion:*' menu select

# Make completion case-insensitive ("doc" -> "Documents")
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Local extras: colored, grouped, labelled completion lists
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{blue}── %d ──%f'
zstyle ':completion:*:warnings' format '%F{red}no matches%f'

# =========================================================
# Fuzzy finder (system key-bindings; re-bound after zsh-vi-mode in bindings.zsh)
# =========================================================

# macOS / Homebrew (Apple Silicon)
if [[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]]; then
  source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
  source /opt/homebrew/opt/fzf/shell/completion.zsh
fi

# macOS / Homebrew (Intel)
if [[ -f /usr/local/opt/fzf/shell/key-bindings.zsh ]]; then
  source /usr/local/opt/fzf/shell/key-bindings.zsh
  source /usr/local/opt/fzf/shell/completion.zsh
fi

# Arch
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
  source /usr/share/fzf/completion.zsh
fi

# Ubuntu
if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
  source /usr/share/doc/fzf/examples/completion.zsh
fi

# =========================================================
# Modular Config Files
# =========================================================

source "$ZDOTDIR/fzf.zsh"       # fzf configuration
source "$ZDOTDIR/aliases.zsh"   # aliases
source "$ZDOTDIR/bindings.zsh"  # custom keybindings (+ zvm_after_init hook)
source "$ZDOTDIR/plugins.zsh"   # plugins and plugin manager
source "$ZDOTDIR/prompt.zsh"    # prompt/theme

# =========================================================
# zoxide (init LAST per zoxide doctor; --cmd cd so `cd` is smart navigation)
# =========================================================

eval "$(zoxide init zsh --cmd cd)"

# =========================================================
# Node / NVM
# =========================================================

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
