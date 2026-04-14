#!/usr/bin/env bash
# Phase 50 — post-install: submodules, TPM, git identity, theme-sync, chsh.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
load_machine_conf

info "updating git submodules"
(
    cd "$JIMDOTS_REPO"
    run git submodule update --init --recursive
)

if [[ -n "${GIT_NAME:-}" ]]; then
    run git config --global user.name "$GIT_NAME"
    ok "git user.name set"
fi
if [[ -n "${GIT_EMAIL:-}" ]]; then
    run git config --global user.email "$GIT_EMAIL"
    ok "git user.email set"
fi

info "TPM (tmux plugin manager)"
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    run git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
if [[ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]]; then
    run "$HOME/.tmux/plugins/tpm/bin/install_plugins" || warn "TPM install_plugins returned non-zero (safe to retry)"
fi

info "browser theme-sync bootstraps"
if [[ -x "$JIMDOTS_REPO/zen/setup-live-theme-sync.sh" ]]; then
    run "$JIMDOTS_REPO/zen/setup-live-theme-sync.sh" || warn "zen setup returned non-zero"
fi
if command -v firefox >/dev/null 2>&1 && [[ -x "$JIMDOTS_REPO/firefox/setup-live-theme-sync.sh" ]]; then
    run "$JIMDOTS_REPO/firefox/setup-live-theme-sync.sh" || warn "firefox setup returned non-zero"
fi

info "quill-polkit build"
polkit_dir="$JIMDOTS_REPO/quickshell/quill-polkit"
if [[ -d "$polkit_dir" ]]; then
    if [[ -x "$polkit_dir/install.sh" ]]; then
        ( cd "$polkit_dir" && run ./install.sh ) || warn "quill-polkit install.sh returned non-zero"
    elif [[ -f "$polkit_dir/Makefile" ]]; then
        ( cd "$polkit_dir" && run make && sudo_run make install ) || warn "quill-polkit make returned non-zero"
    else
        warn "quill-polkit submodule has no install.sh or Makefile — skipping build"
    fi
else
    warn "quill-polkit submodule directory missing"
fi

info "default shell"
zsh_bin="$(command -v zsh || true)"
if [[ -n "$zsh_bin" && "${SHELL##*/}" != "zsh" ]]; then
    if confirm "Change default shell to $zsh_bin?" y; then
        run chsh -s "$zsh_bin"
    fi
fi

warn "reminder: run 'nvim' once to bootstrap LazyVim plugins"
warn "reminder: reboot to pick up greetd + group changes + (if set) resume kernel param"

ok "post-install complete"
