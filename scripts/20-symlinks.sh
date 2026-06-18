#!/usr/bin/env bash
# Phase 20 — create dotfile symlinks per symlinks.txt.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

manifest="$JIMDOTS_REPO/symlinks.txt"
[[ -f "$manifest" ]] || die "missing $manifest"

while IFS='|' read -r src dest; do
    src="${src#"${src%%[![:space:]]*}"}"; src="${src%"${src##*[![:space:]]}"}"
    dest="${dest#"${dest%%[![:space:]]*}"}"; dest="${dest%"${dest##*[![:space:]]}"}"
    [[ -z "$src" || "${src:0:1}" == "#" ]] && continue
    [[ -z "$dest" ]] && { warn "no dest for src=$src, skipping"; continue; }

    abs_src="$JIMDOTS_REPO/$src"
    abs_dest="$HOME/$dest"

    if [[ ! -e "$abs_src" ]]; then
        warn "source missing: $abs_src — skipping"
        continue
    fi

    safe_link "$abs_src" "$abs_dest"
done < "$manifest"

# Hyprland hard-sources these gitignored machine-local files; stub them if
# absent so a fresh clone doesn't error with "file not present".
for stub in hypr/local.conf hypr/quickshell-theme.conf; do
    abs_stub="$JIMDOTS_REPO/$stub"
    if [[ ! -e "$abs_stub" ]]; then
        run touch "$abs_stub"
        info "stubbed missing $stub"
    fi
done

ok "symlinks applied"
