#!/bin/sh
data=$(cat)
[ -z "$data" ] && exit 0
printf '%s' "$data" | wl-copy
