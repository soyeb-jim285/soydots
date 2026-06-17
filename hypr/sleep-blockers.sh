#!/usr/bin/env bash
# Report apps holding a block-mode inhibitor that prevents suspend / lid-sleep.
# Block-mode = hard veto (logind refuses to sleep). Delay-mode is normal, ignored.
# Bound to a key for on-demand "why won't it sleep?" checks.

mapfile -t blocklines < <(systemd-inhibit --list --no-legend 2>/dev/null | awk '$NF=="block"')

if [ "${#blocklines[@]}" -eq 0 ]; then
    notify-send -t 3000 "✅ Sleep not blocked" "No block-mode inhibitors. Lid-close / idle will suspend."
    exit 0
fi

body=""
for line in "${blocklines[@]}"; do
    who=${line%% *}
    what=$(grep -oE '(shutdown|sleep|idle|handle-lid-switch|handle-power-key|handle-suspend-key|handle-hibernate-key)' <<<"$line" | paste -sd, -)
    body+="• ${who} [${what}]"$'\n'
done

notify-send -u critical -t 8000 "🚫 ${#blocklines[@]} app(s) blocking sleep" "${body%$'\n'}"
