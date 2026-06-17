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

info "bundled fonts"
font_src="$JIMDOTS_REPO/fonts"
font_dest="$HOME/.local/share/fonts"
if [[ -d "$font_src" ]]; then
    run mkdir -p "$font_dest"
    installed_any=0
    while IFS= read -r -d '' f; do
        name="$(basename "$f")"
        if [[ -f "$font_dest/$name" ]] && cmp -s "$f" "$font_dest/$name"; then
            continue
        fi
        run install -Dm644 "$f" "$font_dest/$name"
        installed_any=1
    done < <(find "$font_src" -type f \( -iname '*.ttf' -o -iname '*.otf' \) -print0)
    if [[ "$installed_any" == "1" ]] && command -v fc-cache >/dev/null 2>&1; then
        run fc-cache -f "$font_dest"
    fi
    ok "fonts synced to $font_dest"
else
    warn "no fonts/ directory in repo — skipping font install"
fi

info "gtk theme (gsettings for GTK4/libadwaita apps)"
# GTK3 apps read ~/.config/gtk-3.0/settings.ini (symlinked from repo), but
# GTK4/libadwaita apps ignore gtk-theme-name and read gsettings instead.
# Set both the theme and a dark color-scheme so file-chooser portals and
# other GTK apps render dark catppuccin to match the Qt/kvantum side.
if command -v gsettings >/dev/null 2>&1; then
    run gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-lavender-standard+default' || warn "gsettings gtk-theme failed"
    run gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' || true
    run gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
    ok "gtk gsettings applied"
else
    warn "gsettings missing — GTK4/libadwaita apps will not pick up the theme"
fi

info "TPM (tmux plugin manager)"
tpm_dir="$HOME/.config/tmux/plugins/tpm"  # radley layout: TMUX_PLUGIN_MANAGER_PATH=~/.config/tmux/plugins
if [[ ! -d "$tpm_dir" ]]; then
    run git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
fi
if [[ -x "$tpm_dir/bin/install_plugins" ]]; then
    run "$tpm_dir/bin/install_plugins" || warn "TPM install_plugins returned non-zero (safe to retry)"
fi

# Seed quickshell-tmux.conf so first-launch tmux has pills + top status,
# before quickshell has had a chance to regenerate it.
info "seeding quickshell-tmux.conf"
run mkdir -p "$HOME/.config/tmux"
run python3 "$JIMDOTS_REPO/tmux/write-quickshell-conf.py" \
    '{"statusBottom":false,"pill":true,"modules_right":"directory","clockFormat":""}' \
    || warn "quickshell-tmux.conf seed returned non-zero"

info "flatpak: flathub remote"
if command -v flatpak >/dev/null 2>&1; then
    # User-scope remote matches the launcher's default (--user install scope),
    # so users don't need sudo to install apps from the launcher.
    if ! flatpak remote-list --user 2>/dev/null | awk '{print $1}' | grep -qx flathub; then
        run flatpak remote-add --user --if-not-exists flathub \
            https://flathub.org/repo/flathub.flatpakrepo
        ok "flathub remote added (--user)"
    else
        log "flathub remote already present (--user)"
    fi
    # Warm the appstream cache so the launcher's `flatpak search` returns
    # results immediately — otherwise the first few searches on a fresh
    # install hit an empty cache and look broken.
    run flatpak update --appstream --user -y || warn "appstream sync returned non-zero"
else
    warn "flatpak not installed — skipping flathub remote setup"
fi

info "xdg-mime: kitty-nvim as default for text/code files"
kitty_nvim_desktop="$JIMDOTS_REPO/applications/kitty-nvim.desktop"
if command -v xdg-mime >/dev/null 2>&1 && [[ -f "$kitty_nvim_desktop" ]]; then
    # Refresh the user desktop DB so xdg-mime can resolve kitty-nvim.desktop.
    # (No-op if the symlink phase already ran update-desktop-database.)
    if command -v update-desktop-database >/dev/null 2>&1; then
        run update-desktop-database "$HOME/.local/share/applications" \
            || warn "update-desktop-database returned non-zero"
    fi
    mime_line="$(grep -E '^MimeType=' "$kitty_nvim_desktop" | sed 's/^MimeType=//')"
    IFS=';' read -r -a _mimes <<< "$mime_line"
    for m in "${_mimes[@]}"; do
        [[ -z "$m" ]] && continue
        run xdg-mime default kitty-nvim.desktop "$m"
    done
    ok "kitty-nvim.desktop registered for ${#_mimes[@]} MIME types"
else
    warn "xdg-mime or kitty-nvim.desktop missing — skipping file-manager handler setup"
fi

info "xdg-mime: zen-browser as default web browser"
if command -v xdg-mime >/dev/null 2>&1 && [[ -f /usr/share/applications/zen.desktop ]]; then
    for m in x-scheme-handler/http x-scheme-handler/https x-scheme-handler/about \
             x-scheme-handler/unknown text/html application/xhtml+xml; do
        run xdg-mime default zen.desktop "$m"
    done
    if command -v xdg-settings >/dev/null 2>&1; then
        run xdg-settings set default-web-browser zen.desktop || warn "xdg-settings default-web-browser failed"
    fi
    ok "zen.desktop registered as default browser"
else
    warn "xdg-mime or zen.desktop missing — skipping default browser setup"
fi

info "zen: enforce system color-scheme follow via policies"
zen_policy_src="$JIMDOTS_REPO/zen/policies.json"
if [[ -d /opt/zen-browser-bin && -f "$zen_policy_src" ]]; then
    # /opt path is read by Zen unconditionally; AUR updates may reset it,
    # so re-running setup re-applies. Also drop a copy under /etc for users
    # whose Zen build prefers that path.
    sudo_run install -Dm644 "$zen_policy_src" /opt/zen-browser-bin/distribution/policies.json
    sudo_run install -Dm644 "$zen_policy_src" /etc/zen/policies/policies.json
    ok "zen policies installed (system color-scheme follow enabled)"
else
    warn "zen install or policy source missing — skipping zen policy install"
fi

info "plocate database (initial seed)"
if command -v updatedb >/dev/null 2>&1; then
    # The plocate package ships an empty /var/lib/plocate/plocate.db
    # placeholder on install, so a -f test always passes. We need -s
    # (non-empty) to detect a real index. Run updatedb once now so the
    # launcher's `'foo` file search returns results immediately; the
    # plocate-updatedb.timer enabled in the services phase keeps it fresh.
    if [[ ! -s /var/lib/plocate/plocate.db ]]; then
        sudo_run updatedb || warn "initial updatedb returned non-zero"
    else
        log "plocate database already populated — skipping initial seed"
    fi
else
    warn "updatedb not installed — file search will be empty until plocate is installed"
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
