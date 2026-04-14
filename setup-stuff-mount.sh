#!/bin/bash
# Interactive partition auto-mount setup via fstab

set -euo pipefail

# Colors
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

info()  { echo -e "  ${CYAN}>${RESET} $1"; }
ok()    { echo -e "  ${GREEN}✓${RESET} $1"; }
warn()  { echo -e "  ${YELLOW}!${RESET} $1"; }
err()   { echo -e "  ${RED}✗${RESET} $1"; }

divider() { echo -e "  ${DIM}$(printf '%.0s─' {1..50})${RESET}"; }

# Check for fzf
if ! command -v fzf &>/dev/null; then
    err "fzf is required. Install it first: sudo pacman -S fzf"
    exit 1
fi

# Must be root
if [[ $EUID -ne 0 ]]; then
    err "This script must be run as root (sudo)."
    exit 1
fi

echo
echo -e "  ${BOLD}Partition Auto-Mount Setup${RESET}"
divider

# Gather partitions (exclude loop, ram, rom devices)
mapfile -t PARTS < <(lsblk -rno NAME,SIZE,FSTYPE,MOUNTPOINT | awk '$3 != "" && $1 !~ /^(loop|ram|rom)/ { print $0 }')

if [[ ${#PARTS[@]} -eq 0 ]]; then
    err "No partitions with filesystems found."
    exit 1
fi

# Build fzf entries
fzf_entries=()
for i in "${!PARTS[@]}"; do
    read -r name size fstype mount <<< "${PARTS[$i]}"
    if [[ -n "$mount" ]]; then
        status="$mount"
    else
        status="unmounted"
    fi
    fzf_entries+=("$(printf "/dev/%-12s  %8s  %-6s  %s" "$name" "$size" "$fstype" "$status")")
done

# Partition selection via fzf
echo
selection=$(printf '%s\n' "${fzf_entries[@]}" | fzf \
    --height=~20 \
    --layout=reverse \
    --border=rounded \
    --prompt="  partition > " \
    --header="  DEVICE            SIZE  TYPE    MOUNT" \
    --header-first \
    --no-multi \
    --ansi \
    --color="pointer:green,prompt:cyan,header:dim,border:dim") || {
    info "Cancelled."
    exit 0
}

# Extract device name from selection
selected_dev=$(echo "$selection" | awk '{print $1}')
DEVICE="$selected_dev"

# Find the matching partition data
for i in "${!PARTS[@]}"; do
    read -r name size fstype mount <<< "${PARTS[$i]}"
    if [[ "/dev/$name" == "$DEVICE" ]]; then
        break
    fi
done

# Get UUID
eval "$(blkid -o export "$DEVICE" 2>/dev/null)" || true

if [[ -z "${UUID:-}" ]]; then
    err "Could not determine UUID for $DEVICE"
    exit 1
fi

TYPE="${TYPE:-$fstype}"

echo
info "Selected: ${BOLD}$DEVICE${RESET}  (${TYPE}, ${size}, UUID=${DIM}${UUID}${RESET})"

# Already mounted warning
if [[ -n "$mount" ]]; then
    warn "Currently mounted at ${BOLD}$mount${RESET}"
    read -rp "  Continue anyway? [y/N]: " confirm
    [[ "${confirm,,}" == "y" ]] || exit 0
fi

# Mount point selection via fzf
echo
common_mounts=("/stuff" "/mnt/${name}" "/media/${name}" "/data" "custom...")
MOUNT_POINT=$(printf '%s\n' "${common_mounts[@]}" | fzf \
    --height=~10 \
    --layout=reverse \
    --border=rounded \
    --prompt="  mount point > " \
    --header="  Select or type a mount point" \
    --header-first \
    --no-multi \
    --print-query \
    --color="pointer:green,prompt:cyan,header:dim,border:dim" | tail -1) || {
    info "Cancelled."
    exit 0
}

if [[ "$MOUNT_POINT" == "custom..." || -z "$MOUNT_POINT" ]]; then
    read -rp "  Enter mount point: " MOUNT_POINT
fi

MOUNT_POINT="${MOUNT_POINT:-/stuff}"

# Validate mount point path
if [[ "$MOUNT_POINT" != /* ]]; then
    err "Mount point must be an absolute path."
    exit 1
fi

# Mount options via fzf
echo
opt_entries=(
    "defaults"
    "defaults,noatime"
    "defaults,noatime,nofail"
    "custom..."
)
MOUNT_OPTS=$(printf '%s\n' "${opt_entries[@]}" | fzf \
    --height=~8 \
    --layout=reverse \
    --border=rounded \
    --prompt="  options > " \
    --header="  Select mount options" \
    --header-first \
    --no-multi \
    --color="pointer:green,prompt:cyan,header:dim,border:dim") || {
    info "Cancelled."
    exit 0
}

if [[ "$MOUNT_OPTS" == "custom..." ]]; then
    read -rp "  Enter mount options: " MOUNT_OPTS
    MOUNT_OPTS="${MOUNT_OPTS:-defaults}"
fi

# Summary
echo
divider
echo
echo -e "  ${BOLD}Summary${RESET}"
echo
echo -e "  Device:      ${BOLD}$DEVICE${RESET}"
echo -e "  UUID:        ${DIM}$UUID${RESET}"
echo -e "  Filesystem:  $TYPE"
echo -e "  Mount point: ${BOLD}$MOUNT_POINT${RESET}"
echo -e "  Options:     $MOUNT_OPTS"
echo
echo -e "  fstab entry:"
echo -e "  ${DIM}UUID=$UUID  $MOUNT_POINT  $TYPE  $MOUNT_OPTS  0  2${RESET}"
echo
divider
echo

read -rp "  Apply changes? [y/N]: " confirm
if [[ "${confirm,,}" != "y" ]]; then
    info "Aborted."
    exit 0
fi

echo

# Create mount point
if [[ ! -d "$MOUNT_POINT" ]]; then
    mkdir -p "$MOUNT_POINT"
    ok "Created $MOUNT_POINT"
fi

# Check if already in fstab
if grep -q "$UUID" /etc/fstab; then
    warn "Entry for this UUID already exists in /etc/fstab"
    read -rp "  Replace existing entry? [y/N]: " replace
    if [[ "${replace,,}" == "y" ]]; then
        cp /etc/fstab /etc/fstab.bak
        ok "Backed up /etc/fstab to /etc/fstab.bak"
        sed -i "\|$UUID|d" /etc/fstab
        echo "UUID=$UUID  $MOUNT_POINT  $TYPE  $MOUNT_OPTS  0  2" >> /etc/fstab
        ok "Replaced fstab entry"
    else
        info "Kept existing entry."
    fi
else
    cp /etc/fstab /etc/fstab.bak
    ok "Backed up /etc/fstab to /etc/fstab.bak"
    echo "UUID=$UUID  $MOUNT_POINT  $TYPE  $MOUNT_OPTS  0  2" >> /etc/fstab
    ok "Added fstab entry"
fi

# Unmount from current location if mounted elsewhere
if [[ -n "$mount" && "$mount" != "$MOUNT_POINT" ]]; then
    info "Unmounting from ${BOLD}$mount${RESET}..."
    if umount "$DEVICE" 2>&1; then
        ok "Unmounted from $mount"
    else
        err "Failed to unmount $DEVICE from $mount"
        warn "Try closing any programs using that path, then run again."
        exit 1
    fi
fi

# Mount now
echo
read -rp "  Mount now? [Y/n]: " mount_now
if [[ "${mount_now,,}" != "n" ]]; then
    if mount -a 2>&1; then
        ok "Mounted at $MOUNT_POINT"
        echo
        info "$(df -h "$MOUNT_POINT" | tail -1)"
    else
        err "Mount failed — check the fstab entry"
        exit 1
    fi
fi

echo
ok "Done. Partition will auto-mount on boot."
echo
