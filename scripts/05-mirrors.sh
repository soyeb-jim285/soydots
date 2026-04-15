#!/usr/bin/env bash
# Phase 05 — tune pacman.conf and refresh mirrorlist via reflector.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

PACMAN_CONF="/etc/pacman.conf"
MIRRORLIST="/etc/pacman.d/mirrorlist"

# --- pacman.conf tweaks ---------------------------------------------------

tune_pacman_conf() {
    local parallel="$1"
    local backup; backup="${PACMAN_CONF}.bak.$(date +%s)"
    sudo_run cp -a "$PACMAN_CONF" "$backup"
    log "backed up $PACMAN_CONF -> $backup"

    # Color: uncomment if commented, add under [options] if missing.
    if sudo grep -qE '^\s*#\s*Color' "$PACMAN_CONF"; then
        sudo_run sed -i -E 's/^\s*#\s*Color/Color/' "$PACMAN_CONF"
    elif ! sudo grep -qE '^\s*Color' "$PACMAN_CONF"; then
        sudo_run sed -i -E '/^\[options\]/a Color' "$PACMAN_CONF"
    fi

    # ILoveCandy: pacman easter egg, add under [options] if missing.
    if ! sudo grep -qE '^\s*ILoveCandy' "$PACMAN_CONF"; then
        sudo_run sed -i -E '/^\[options\]/a ILoveCandy' "$PACMAN_CONF"
    fi

    # ParallelDownloads: set/replace to requested value.
    if sudo grep -qE '^\s*#?\s*ParallelDownloads' "$PACMAN_CONF"; then
        sudo_run sed -i -E "s|^\s*#?\s*ParallelDownloads\s*=.*|ParallelDownloads = ${parallel}|" "$PACMAN_CONF"
    else
        sudo_run sed -i -E "/^\[options\]/a ParallelDownloads = ${parallel}" "$PACMAN_CONF"
    fi

    ok "pacman.conf tuned (Color, ILoveCandy, ParallelDownloads=${parallel})"
}

# --- mirror selection -----------------------------------------------------

pick_countries() {
    # Returns a comma-separated country list on stdout, or empty to skip reflector.
    local all
    all="$(reflector --list-countries 2>/dev/null | awk 'NR>2 {print $1}' | sort -u)"
    [[ -z "$all" ]] && return 0

    if _has_gum && [[ -t 0 ]]; then
        # gum choose --no-limit returns one per line
        local chosen
        chosen="$(printf '%s\n' "$all" | gum choose --no-limit --height 20 \
            --header 'Select mirror countries (space to toggle, enter to confirm, esc to skip)')" || true
        [[ -z "$chosen" ]] && return 0
        printf '%s' "$chosen" | paste -sd, -
        return 0
    fi

    if command -v fzf >/dev/null 2>&1 && [[ -t 0 ]]; then
        local chosen
        chosen="$(printf '%s\n' "$all" | fzf -m --prompt='mirror countries> ' --header='tab to multi-select, enter to confirm, esc to skip')" || true
        [[ -z "$chosen" ]] && return 0
        printf '%s' "$chosen" | paste -sd, -
        return 0
    fi

    # Fallback: plain prompt
    local reply
    reply="$(prompt_default "Mirror countries (comma-separated, empty to skip)" "")"
    printf '%s' "$reply"
}

refresh_mirrors() {
    if ! command -v reflector >/dev/null 2>&1; then
        info "installing reflector"
        sudo_run pacman -S --needed --noconfirm reflector
    fi

    local countries
    countries="$(pick_countries)"
    if [[ -z "$countries" ]]; then
        warn "no countries selected — skipping reflector"
        return 0
    fi

    info "ranking mirrors for: $countries"
    local backup; backup="${MIRRORLIST}.bak.$(date +%s)"
    sudo_run cp -a "$MIRRORLIST" "$backup"
    log "backed up $MIRRORLIST -> $backup"

    sudo_run reflector \
        --country "$countries" \
        --protocol https \
        --latest 20 \
        --age 24 \
        --sort rate \
        --save "$MIRRORLIST"
    ok "mirrorlist updated"

    info "refreshing package databases"
    sudo_run pacman -Syy
}

# --- main -----------------------------------------------------------------

if confirm "Tune /etc/pacman.conf (Color, ILoveCandy, ParallelDownloads)?" y; then
    parallel="$(prompt_default "ParallelDownloads" "8")"
    [[ "$parallel" =~ ^[0-9]+$ ]] || die "ParallelDownloads must be an integer, got: $parallel"
    tune_pacman_conf "$parallel"
else
    warn "skipping pacman.conf tweaks"
fi

if confirm "Refresh mirrorlist with reflector now?" y; then
    refresh_mirrors
else
    warn "skipping reflector"
fi

ok "mirrors phase complete"
