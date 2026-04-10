# ~/.zshrc - interactive shell config

# ── History ──────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY          # share across sessions
setopt HIST_IGNORE_ALL_DUPS   # deduplicate
setopt HIST_IGNORE_SPACE      # prefix with space to skip history
setopt HIST_REDUCE_BLANKS     # trim whitespace
setopt INC_APPEND_HISTORY     # write immediately, not on exit

# ── General Options ──────────────────────────────────────
setopt AUTO_CD                # type dir name to cd
setopt INTERACTIVE_COMMENTS   # allow # comments in interactive shell
setopt NO_BEEP
setopt GLOB_DOTS              # include dotfiles in globbing

# ── Vi Mode ──────────────────────────────────────────────
bindkey -v
export KEYTIMEOUT=1

# restore useful emacs bindings in vi insert mode
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^W' backward-kill-word
bindkey '^U' backward-kill-line
bindkey '^K' kill-line
bindkey '^Y' yank
bindkey '^?' backward-delete-char   # backspace
bindkey '^H' backward-delete-char
bindkey '\e\x7f' backward-kill-word  # ctrl+backspace (via kitty remap)

# ── Completion ───────────────────────────────────────────
autoload -Uz compinit
compinit -d ~/.cache/zsh/zcompdump-$ZSH_VERSION
mkdir -p ~/.cache/zsh

zstyle ':completion:*' menu select                   # arrow key menu
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'  # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # colored completions
zstyle ':completion:*' group-name ''                  # group by type
zstyle ':completion:*:descriptions' format '%F{blue}── %d ──%f'
zstyle ':completion:*:warnings' format '%F{red}no matches%f'

# ── Plugins (Arch packages) ─────────────────────────────
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# autosuggestion style
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
bindkey '^F' autosuggest-accept  # Ctrl+F to accept suggestion

# ── Syntax Highlighting (uses ANSI colors so it follows kitty theme) ──
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=blue'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=blue'
ZSH_HIGHLIGHT_STYLES[alias]='fg=blue'
ZSH_HIGHLIGHT_STYLES[function]='fg=blue'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red'
ZSH_HIGHLIGHT_STYLES[path]='fg=yellow,underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=magenta'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=green'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=green'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=green'
ZSH_HIGHLIGHT_STYLES[comment]='fg=8'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=blue'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=magenta'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=magenta'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=green'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=green'

# ── fzf ──────────────────────────────────────────────────
source <(fzf --zsh)

# Catppuccin Mocha fzf colors
export FZF_DEFAULT_OPTS=" \
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
  --color=selected-bg:#45475a \
  --border=rounded --margin=0,1 --padding=0,1"

export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {} 2>/dev/null || eza --icons --color=always {}'"
export FZF_ALT_C_OPTS="--preview 'eza --icons --color=always --tree --level=2 {}'"

# ── zoxide ───────────────────────────────────────────────
eval "$(zoxide init zsh --cmd cd)"

# ── Aliases ──────────────────────────────────────────────
alias ls='eza --icons --color=always'
alias ll='eza --icons --color=always -la'
alias lt='eza --icons --color=always --tree --level=2'
alias la='eza --icons --color=always -a'
alias cat='bat --style=plain'
alias grep='grep --color=auto'

# git shortcuts
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline -20'
alias gp='git push'
alias pushfm='git push && ~/hyprfm/scripts/sync-aur.sh'

# ── Starship Prompt ──────────────────────────────────────
eval "$(starship init zsh)"
