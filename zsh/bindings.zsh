# =========================================================
# Keybindings
# =========================================================

# Cursor shape per vi mode
ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK

# Disable command mode line highlight
ZVM_VI_HIGHLIGHT_BACKGROUND=none
ZVM_VI_HIGHLIGHT_FOREGROUND=none
ZVM_VI_HIGHLIGHT_EXTRASTYLE=none

# zsh-vi-mode resets all bindings on init, so custom bindings
# must be registered via this hook to survive.
zvm_after_init() {
  # ── fzf widgets ─────────────────────────────────────────
  # zsh-vi-mode wipes the fzf bindings sourced in .zshrc; re-source here so
  # Ctrl-R (history) and Ctrl-T (files) actually work under vi-mode.
  [[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
  [[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]] && source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
  [[ -f /usr/local/opt/fzf/shell/key-bindings.zsh ]] && source /usr/local/opt/fzf/shell/key-bindings.zsh
  [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && source /usr/share/doc/fzf/examples/key-bindings.zsh

  # ── word motion ─────────────────────────────────────────
  bindkey '^[[1;5C' forward-word    # Ctrl+Right
  bindkey '^[[1;5D' backward-word   # Ctrl+Left

  # ── emacs-style insert-mode rescue bindings ─────────────
  bindkey '^A' beginning-of-line
  bindkey '^E' end-of-line
  bindkey '^W' backward-kill-word
  bindkey '^U' backward-kill-line
  bindkey '^K' kill-line
  bindkey '^Y' yank
  bindkey '^?' backward-delete-char        # backspace
  bindkey '^H' backward-delete-char
  bindkey '\e\x7f' backward-kill-word      # ctrl+backspace (via kitty remap)

  # ── fzf file picker (no hidden files) ───────────────────
  bindkey '^F' _fzf_file_no_hidden

  # ── autosuggestions ─────────────────────────────────────
  # Accept: → / End (defaults). Ctrl+F is the fzf file picker (radley), so it
  # is NOT bound to accept here; Ctrl+Space is taken by the tmux prefix.
  bindkey '^O' autosuggest-accept          # Ctrl+O accept suggestion (tmux-safe)
  bindkey '^\' autosuggest-toggle          # Ctrl+\ toggle (screen recordings)

  # ── history substring search ────────────────────────────
  bindkey '^[[A' history-substring-search-up    # Up
  bindkey '^[[B' history-substring-search-down  # Down
}
