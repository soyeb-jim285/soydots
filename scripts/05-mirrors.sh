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
    # reflector --list-countries prints: header, dashes, then "Name  Code  Count"
    # We want the full country name (may contain spaces), so strip the trailing
    # two columns instead of taking $1.
    local all
    all="$(reflector --list-countries 2>/dev/null \
        | awk 'NR>2 { sub(/[[:space:]]+[A-Z]{2}[[:space:]]+[0-9]+[[:space:]]*$/, ""); print }' \
        | sort -u)"
    [[ -z "$all" ]] && return 0

    # Preferred: fzf (searchable, type-ahead filtering, Tab multi-select).
    # Needs a real TTY — redirect in/out to /dev/tty so logging pipelines
    # don't break it.
    if command -v fzf >/dev/null 2>&1 && [[ -r /dev/tty && -w /dev/tty ]]; then
        local chosen
        chosen="$(printf '%s\n' "$all" | fzf \
            --multi \
            --height=60% \
            --reverse \
            --prompt='mirror countries> ' \
            --header=$'TYPE to filter  •  TAB to mark  •  ENTER to confirm  •  ESC to skip' \
            </dev/tty >/dev/tty)" || true
        [[ -z "$chosen" ]] && return 0
        printf '%s' "$chosen" | paste -sd, -
        return 0
    fi

    # Fallback: gum filter (also searchable, --no-limit enables multi-select).
    if _has_gum && [[ -t 0 ]]; then
        local chosen
        chosen="$(printf '%s\n' "$all" | gum filter --no-limit --height 20 \
            --placeholder 'type to search, tab to mark, enter to confirm')" || true
        [[ -z "$chosen" ]] && return 0
        printf '%s' "$chosen" | paste -sd, -
        return 0
    fi

    # Last resort: plain prompt.
    local reply
    reply="$(prompt_default "Mirror countries (comma-separated, empty to skip)" "")"
    printf '%s' "$reply"
}

refresh_mirrors() {
    local need=()
    command -v reflector >/dev/null 2>&1 || need+=(reflector)
    command -v fzf       >/dev/null 2>&1 || need+=(fzf)
    if (( ${#need[@]} > 0 )); then
        info "installing: ${need[*]}"
        sudo_run pacman -S --needed --noconfirm "${need[@]}"
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

# Default to "no" on reruns where the tweaks are already in place.
pacman_tuned=n
if sudo grep -qE '^\s*ILoveCandy' "$PACMAN_CONF" \
    && sudo grep -qE '^\s*Color' "$PACMAN_CONF" \
    && sudo grep -qE '^\s*ParallelDownloads\s*=' "$PACMAN_CONF"; then
    pacman_tuned=y
    info "pacman.conf already tuned"
fi

if [[ "$pacman_tuned" == "y" ]]; then
    default_tune=n
else
    default_tune=y
fi
if confirm "Tune /etc/pacman.conf (Color, ILoveCandy, ParallelDownloads)?" "$default_tune"; then
    parallel="$(prompt_default "ParallelDownloads" "8")"
    [[ "$parallel" =~ ^[0-9]+$ ]] || die "ParallelDownloads must be an integer, got: $parallel"
    tune_pacman_conf "$parallel"
else
    warn "skipping pacman.conf tweaks"
fi

# Default reflector to "no" if the mirrorlist was refreshed recently (<7 days).
default_reflect=y
if [[ -f "$MIRRORLIST" ]]; then
    age_days=$(( ( $(date +%s) - $(stat -c %Y "$MIRRORLIST") ) / 86400 ))
    if (( age_days < 7 )); then
        default_reflect=n
        info "mirrorlist refreshed ${age_days}d ago"
    fi
fi
if confirm "Refresh mirrorlist with reflector now?" "$default_reflect"; then
    refresh_mirrors
else
    warn "skipping reflector"
fi

ok "mirrors phase complete"
