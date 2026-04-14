# jimdots Setup Script Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an idempotent orchestrator (`setup.sh` + phased `scripts/NN-*.sh`) that recreates Jim's Arch + Hyprland + Quickshell desktop from the `jimdots` repo on a fresh install, and is safe to re-run on any existing machine.

**Architecture:** Phase-based bash. `setup.sh` dispatches to numbered scripts under `scripts/` that each do one concern (preflight, packages, symlinks, system, services, post, nvidia). Shared helpers live in `scripts/lib.sh`. Data is declarative where possible (`packages/*.txt`, `symlinks.txt`, `etc/`); code is only used where a check-then-act guard is needed. Machine-specific values live in a gitignored `machine.local.conf` populated by interactive prompts on first run.

**Tech Stack:** bash 5, pacman, yay, systemd, `install(1)`, `ln -sfn`, `cmp`, `grep`, `sed`.

Note: This project has no automated test suite — validation is done by running `--dry-run`, `shellcheck`, and a final "fresh-like" self-run. TDD isn't applied per-file; each task ends with a validation step appropriate to the artifact being built.

---

## File Structure

Created under `jimdots/`:

- `setup.sh` — orchestrator: arg parsing, phase dispatch, `--dry-run`, `--only`, `--yes`
- `scripts/lib.sh` — `log/warn/die/confirm/is_pkg/safe_link/copy_etc/ensure_line` helpers, log sink, color detection, dry-run gate
- `scripts/00-preflight.sh` — arch/sudo/network/yay bootstrap + `machine.local.conf` prompts
- `scripts/10-packages.sh` — pacman + yay installs
- `scripts/20-symlinks.sh` — reads `symlinks.txt`, creates links with backup
- `scripts/30-system.sh` — `/etc` file copies, mkinitcpio HOOKS, i2c group/module, bootloader hint
- `scripts/40-services.sh` — system + user `systemctl enable --now`
- `scripts/50-post.sh` — submodules, TPM, git identity, theme-sync, polkit build, chsh
- `scripts/60-nvidia.sh` — detect + prompt + delegate to existing `setup-nvidia.sh`
- `packages/pacman.txt` — pacman package list (from `tasks.md` "Installed")
- `packages/aur.txt` — AUR package list
- `symlinks.txt` — `<repo-relative-src>|<home-relative-dest>` pairs
- `etc/greetd/config.toml` — captured from `/etc/greetd/config.toml`
- `etc/vconsole.conf` — captured from `/etc/vconsole.conf`
- `etc/tty-colors.pal` — captured from `/etc/tty-colors.pal`
- `etc/systemd/system/tty-colors.service` — captured from `/etc/systemd/system/tty-colors.service`
- `etc/systemd/sleep.conf.d/hibernate.conf` — authored (current system doesn't have it yet)

Modified:

- `.gitignore` — add `machine.local.conf` and `~/.cache/jimdots-setup.log` doesn't apply (outside repo)

---

## Task 1: Repo scaffold + .gitignore

**Files:**
- Create: `scripts/`, `packages/`, `etc/`, `etc/greetd/`, `etc/systemd/system/`, `etc/systemd/sleep.conf.d/`
- Modify: `.gitignore`

- [ ] **Step 1: Create directory skeleton**

```bash
cd /home/jim/jimdots
mkdir -p scripts packages etc/greetd etc/systemd/system etc/systemd/sleep.conf.d
```

- [ ] **Step 2: Add machine.local.conf to .gitignore**

Read current `.gitignore`, then append (only if not already present):

```
machine.local.conf
```

Use:
```bash
grep -qxF 'machine.local.conf' .gitignore || echo 'machine.local.conf' >> .gitignore
```

- [ ] **Step 3: Verify structure**

Run: `ls scripts packages etc etc/greetd etc/systemd/system etc/systemd/sleep.conf.d`
Expected: all directories exist and are empty.

- [ ] **Step 4: Commit**

```bash
git add .gitignore
git commit -m "chore: scaffold setup script directories"
```

(empty directories aren't tracked by git; subsequent tasks will populate them.)

---

## Task 2: Shared library (`scripts/lib.sh`)

**Files:**
- Create: `scripts/lib.sh`

- [ ] **Step 1: Write `scripts/lib.sh`**

```bash
#!/usr/bin/env bash
# Shared helpers for jimdots setup scripts.
# Source this from each phase script: . "$(dirname "$0")/lib.sh"

set -euo pipefail

: "${JIMDOTS_REPO:="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"}"
: "${JIMDOTS_LOG:="$HOME/.cache/jimdots-setup.log"}"
: "${JIMDOTS_DRY_RUN:=0}"
: "${JIMDOTS_ASSUME_YES:=0}"

mkdir -p "$(dirname "$JIMDOTS_LOG")"

if [[ -t 1 ]]; then
    C_RESET=$'\e[0m'; C_DIM=$'\e[2m'; C_RED=$'\e[31m'; C_YEL=$'\e[33m'; C_GRN=$'\e[32m'; C_BLU=$'\e[34m'
else
    C_RESET=""; C_DIM=""; C_RED=""; C_YEL=""; C_GRN=""; C_BLU=""
fi

_ts() { date '+%Y-%m-%d %H:%M:%S'; }

log()  { printf '%s[%s]%s %s\n' "$C_DIM" "$(_ts)" "$C_RESET" "$*" | tee -a "$JIMDOTS_LOG" >&2; }
info() { printf '%s==>%s %s\n' "$C_BLU" "$C_RESET" "$*" | tee -a "$JIMDOTS_LOG" >&2; }
ok()   { printf '%s ok%s %s\n' "$C_GRN" "$C_RESET" "$*" | tee -a "$JIMDOTS_LOG" >&2; }
warn() { printf '%s warn%s %s\n' "$C_YEL" "$C_RESET" "$*" | tee -a "$JIMDOTS_LOG" >&2; }
die()  { printf '%s err%s %s\n' "$C_RED" "$C_RESET" "$*" | tee -a "$JIMDOTS_LOG" >&2; exit 1; }

dry() { [[ "$JIMDOTS_DRY_RUN" == "1" ]]; }

run() {
    # Logs and executes a command. Honors dry-run.
    log "+ $*"
    if dry; then return 0; fi
    "$@"
}

sudo_run() {
    log "+ sudo $*"
    if dry; then return 0; fi
    sudo "$@"
}

confirm() {
    # confirm "Question?" [default:y|n]
    local q="$1" default="${2:-n}" reply
    if [[ "$JIMDOTS_ASSUME_YES" == "1" ]]; then return 0; fi
    local hint="[y/N]"; [[ "$default" == "y" ]] && hint="[Y/n]"
    read -r -p "$q $hint " reply
    reply="${reply:-$default}"
    [[ "$reply" =~ ^[Yy]$ ]]
}

prompt_default() {
    # prompt_default "Label" "default"  -> echoes chosen value (empty ok)
    local label="$1" def="${2:-}" reply
    if [[ -n "$def" ]]; then
        read -r -p "$label [$def]: " reply
        echo "${reply:-$def}"
    else
        read -r -p "$label (empty to skip): " reply
        echo "$reply"
    fi
}

is_pkg_installed() { pacman -Qi "$1" &>/dev/null; }
is_aur_installed() { pacman -Qi "$1" &>/dev/null; }  # yay-installed pkgs show in pacman too

# safe_link <src-abs> <dest-abs>
# Creates parent, backs up any pre-existing non-symlink-to-src at dest, then ln -sfn.
safe_link() {
    local src="$1" dest="$2"
    run mkdir -p "$(dirname "$dest")"
    if [[ -L "$dest" ]]; then
        local cur; cur="$(readlink -f "$dest" || true)"
        if [[ "$cur" == "$(readlink -f "$src")" ]]; then
            ok "link ok: $dest -> $src"
            return 0
        fi
    fi
    if [[ -e "$dest" || -L "$dest" ]]; then
        local bak="${dest}.bak.$(date +%s)"
        warn "backing up existing $dest -> $bak"
        run mv "$dest" "$bak"
    fi
    run ln -sfn "$src" "$dest"
    ok "linked $dest -> $src"
}

# copy_etc <repo-rel-src> <abs-dest> [mode]
# Copies only if dest missing or differs. Requires sudo.
copy_etc() {
    local src="$JIMDOTS_REPO/$1" dest="$2" mode="${3:-644}"
    if [[ ! -f "$src" ]]; then die "missing source: $src"; fi
    if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
        ok "etc up-to-date: $dest"
        return 0
    fi
    sudo_run install -Dm"$mode" "$src" "$dest"
    ok "installed $dest"
}

# ensure_line <file> <line>   (requires write perms or use with sudo_ensure_line)
ensure_line() {
    local file="$1" line="$2"
    grep -qxF "$line" "$file" 2>/dev/null || run bash -c "printf '%s\n' \"$line\" >> \"$file\""
}

sudo_ensure_line() {
    local file="$1" line="$2"
    if sudo grep -qxF "$line" "$file" 2>/dev/null; then
        ok "line present in $file"
        return 0
    fi
    sudo_run bash -c "printf '%s\n' \"$line\" >> \"$file\""
}

# Load machine.local.conf if present
load_machine_conf() {
    local f="$JIMDOTS_REPO/machine.local.conf"
    if [[ -f "$f" ]]; then
        # shellcheck source=/dev/null
        . "$f"
        log "loaded $f"
    fi
}

save_machine_conf() {
    local f="$JIMDOTS_REPO/machine.local.conf"
    {
        echo "# jimdots machine-local config — gitignored"
        echo "# generated $(_ts)"
        for var in HOSTNAME GIT_NAME GIT_EMAIL SWAP_UUID DDC_BUS ENABLE_HIBERNATE; do
            local val="${!var-}"
            [[ -n "$val" ]] && printf '%s=%q\n' "$var" "$val"
        done
    } > "$f"
    ok "wrote $f"
}
```

- [ ] **Step 2: Syntax check**

Run: `bash -n scripts/lib.sh`
Expected: no output, exit 0.

- [ ] **Step 3: shellcheck (install if needed)**

Run: `command -v shellcheck && shellcheck scripts/lib.sh || echo "shellcheck not installed — skipping"`
Expected: no issues, or a note that shellcheck isn't installed. Fix any reported issues before proceeding.

- [ ] **Step 4: Commit**

```bash
git add scripts/lib.sh
git commit -m "feat(setup): shared helpers lib.sh"
```

---

## Task 3: Orchestrator `setup.sh`

**Files:**
- Create: `setup.sh`

- [ ] **Step 1: Write `setup.sh`**

```bash
#!/usr/bin/env bash
# jimdots setup orchestrator.
# Usage:
#   ./setup.sh                       # run all phases
#   ./setup.sh --only symlinks       # run one phase
#   ./setup.sh --only packages,system
#   ./setup.sh --dry-run             # show actions, change nothing
#   ./setup.sh --yes                 # assume yes for confirm prompts
#   ./setup.sh --help

set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
export JIMDOTS_REPO="$REPO"

ONLY=""
export JIMDOTS_DRY_RUN=0
export JIMDOTS_ASSUME_YES=0

usage() {
    cat <<EOF
jimdots setup
Usage: $0 [--only phase[,phase...]] [--dry-run] [--yes] [--help]

Phases (in order):
  preflight packages symlinks system services post nvidia
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --only)    ONLY="$2"; shift 2;;
        --dry-run) JIMDOTS_DRY_RUN=1; shift;;
        --yes)     JIMDOTS_ASSUME_YES=1; shift;;
        -h|--help) usage; exit 0;;
        *) echo "unknown arg: $1" >&2; usage; exit 2;;
    esac
done

# shellcheck source=scripts/lib.sh
. "$REPO/scripts/lib.sh"

declare -a PHASES=(preflight packages symlinks system services post nvidia)
declare -A PHASE_SCRIPT=(
    [preflight]="00-preflight.sh"
    [packages]="10-packages.sh"
    [symlinks]="20-symlinks.sh"
    [system]="30-system.sh"
    [services]="40-services.sh"
    [post]="50-post.sh"
    [nvidia]="60-nvidia.sh"
)

should_run() {
    local name="$1"
    if [[ -z "$ONLY" ]]; then return 0; fi
    local IFS=,
    for p in $ONLY; do [[ "$p" == "$name" ]] && return 0; done
    return 1
}

info "jimdots setup — repo: $REPO"
dry && warn "DRY RUN — no changes will be made"

for phase in "${PHASES[@]}"; do
    if ! should_run "$phase"; then
        log "skipping phase: $phase (filtered by --only)"
        continue
    fi
    script="$REPO/scripts/${PHASE_SCRIPT[$phase]}"
    info "==== phase: $phase ($script) ===="
    if ! bash "$script"; then
        die "phase '$phase' failed — see $JIMDOTS_LOG"
    fi
done

ok "jimdots setup complete"
```

- [ ] **Step 2: Make executable + syntax check**

```bash
chmod +x setup.sh
bash -n setup.sh
```

Expected: no errors.

- [ ] **Step 3: Test help flag**

Run: `./setup.sh --help`
Expected: prints usage, exits 0.

- [ ] **Step 4: Commit**

```bash
git add setup.sh
git commit -m "feat(setup): orchestrator with phase dispatch, --only, --dry-run"
```

---

## Task 4: Preflight phase (`scripts/00-preflight.sh`)

**Files:**
- Create: `scripts/00-preflight.sh`

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Phase 00 — preflight: verify env, bootstrap yay, collect machine config.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

[[ -f /etc/arch-release ]] || die "not running on Arch Linux"

info "refreshing sudo"
sudo -v
( while true; do sleep 60; sudo -n true 2>/dev/null || exit; done ) &
SUDO_KEEPALIVE=$!
trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null || true' EXIT

info "network check"
if ! ping -c1 -W3 archlinux.org >/dev/null 2>&1; then
    die "no network connectivity to archlinux.org"
fi

info "ensuring base-devel and git"
if ! is_pkg_installed base-devel || ! is_pkg_installed git; then
    sudo_run pacman -S --needed --noconfirm base-devel git
fi

if ! command -v yay >/dev/null 2>&1; then
    info "bootstrapping yay from AUR"
    local_tmp="$(mktemp -d)"
    run git clone https://aur.archlinux.org/yay.git "$local_tmp/yay"
    (
        cd "$local_tmp/yay"
        run makepkg -si --noconfirm
    )
    rm -rf "$local_tmp"
fi

# Load or build machine.local.conf
load_machine_conf

if [[ -z "${HOSTNAME:-}" ]]; then
    HOSTNAME="$(prompt_default "Hostname" "$(hostnamectl --static 2>/dev/null || hostname)")"
fi

if [[ -z "${GIT_NAME:-}" ]] && confirm "Configure global git user.name/user.email now?" y; then
    GIT_NAME="$(prompt_default "git user.name" "${GIT_NAME:-}")"
    GIT_EMAIL="$(prompt_default "git user.email" "${GIT_EMAIL:-}")"
fi

if [[ -z "${ENABLE_HIBERNATE:-}" ]]; then
    if confirm "Enable hibernate (requires swap partition)?" n; then
        ENABLE_HIBERNATE=1
    else
        ENABLE_HIBERNATE=0
    fi
fi

if [[ "${ENABLE_HIBERNATE:-0}" == "1" && -z "${SWAP_UUID:-}" ]]; then
    swap_dev="$(swapon --show=NAME --noheadings | head -n1 || true)"
    detected=""
    if [[ -n "$swap_dev" && -b "$swap_dev" ]]; then
        detected="$(blkid -s UUID -o value "$swap_dev" 2>/dev/null || true)"
    fi
    SWAP_UUID="$(prompt_default "Swap partition UUID" "$detected")"
fi

if [[ -z "${DDC_BUS:-}" ]] && command -v ddcutil >/dev/null 2>&1; then
    info "detecting DDC bus (may take a moment)"
    detected_bus="$(ddcutil detect 2>/dev/null | awk '/I2C bus/ {gsub(/[^0-9]/,"",$NF); print $NF; exit}')"
    if [[ -n "$detected_bus" ]]; then
        if confirm "Use detected DDC bus $detected_bus?" y; then
            DDC_BUS="$detected_bus"
        fi
    fi
fi

export HOSTNAME GIT_NAME GIT_EMAIL SWAP_UUID DDC_BUS ENABLE_HIBERNATE
save_machine_conf
ok "preflight complete"
```

- [ ] **Step 2: Make executable + syntax check**

```bash
chmod +x scripts/00-preflight.sh
bash -n scripts/00-preflight.sh
```

Expected: no syntax errors.

- [ ] **Step 3: Dry-run through orchestrator**

Run: `./setup.sh --only preflight --dry-run`
Expected: prompts fire (or skip if `machine.local.conf` already populated), no package installs occur because of dry-run, exits 0. If `machine.local.conf` is created, verify its contents with `cat machine.local.conf`.

- [ ] **Step 4: Commit**

```bash
git add scripts/00-preflight.sh
git commit -m "feat(setup): preflight phase — arch/sudo/yay + machine.local.conf prompts"
```

---

## Task 5: Package lists + packages phase

**Files:**
- Create: `packages/pacman.txt`
- Create: `packages/aur.txt`
- Create: `scripts/10-packages.sh`

- [ ] **Step 1: Write `packages/pacman.txt`**

Seeded from `tasks.md` "Installed" section. Categories as comments.

```
# --- base toolchain ---
base-devel
git
jq
zip
unzip
wl-clipboard

# --- shell + prompt ---
zsh
zsh-autosuggestions
zsh-syntax-highlighting
zsh-completions
starship
zoxide
eza
bat
fzf

# --- terminal + editor ---
kitty
neovim
tmux

# --- fonts ---
ttf-maplemono-nf

# --- wayland / hyprland stack ---
hyprland
hyprlock
hypridle
hyprsunset
hyprshot
qt6-wayland
xdg-desktop-portal-hyprland
uwsm

# --- shell ui / quickshell deps ---
quickshell
python-gobject
python-pillow

# --- display manager ---
greetd
greetd-tuigreet
terminus-font

# --- audio ---
pipewire
pipewire-alsa
pipewire-pulse
wireplumber

# --- bluetooth ---
bluez
bluez-utils

# --- screen / brightness / misc ---
brightnessctl
ddcutil
grim
slurp
swappy
cliphist
fuzzel
upower

# --- theming (qt/gtk) ---
qt6ct
kvantum

# --- monitoring ---
btop

# --- nvidia (installed only if nvidia machine; harmless on others) ---
linux-headers
```

- [ ] **Step 2: Write `packages/aur.txt`**

```
# AUR packages (installed via yay)
yay
dracula-cursors-git
zen-browser-bin
kvantum-theme-catppuccin
awww
hyprpolkitagent
```

Note: `quillpolkit` is built from the submodule in phase 50, not installed via AUR.

- [ ] **Step 3: Write `scripts/10-packages.sh`**

```bash
#!/usr/bin/env bash
# Phase 10 — install pacman + AUR packages.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

read_list() {
    local f="$1"
    [[ -f "$f" ]] || die "missing package list: $f"
    grep -v '^\s*#' "$f" | grep -v '^\s*$' | awk '{print $1}'
}

mapfile -t PAC < <(read_list "$JIMDOTS_REPO/packages/pacman.txt")
mapfile -t AUR < <(read_list "$JIMDOTS_REPO/packages/aur.txt")

info "installing ${#PAC[@]} pacman packages"
if (( ${#PAC[@]} > 0 )); then
    sudo_run pacman -S --needed --noconfirm "${PAC[@]}"
fi

if ! command -v yay >/dev/null 2>&1; then
    die "yay missing — preflight phase must run first"
fi

info "installing ${#AUR[@]} AUR packages"
if (( ${#AUR[@]} > 0 )); then
    run yay -S --needed --noconfirm "${AUR[@]}"
fi

ok "packages installed"
```

- [ ] **Step 4: Make executable + syntax check**

```bash
chmod +x scripts/10-packages.sh
bash -n scripts/10-packages.sh
```

- [ ] **Step 5: Dry-run verification**

Run: `./setup.sh --only packages --dry-run`
Expected: logs `sudo pacman -S --needed --noconfirm ...` followed by `yay -S --needed ...`; no install happens. Review the list for obvious missing packages vs. `tasks.md`.

- [ ] **Step 6: Commit**

```bash
git add packages/pacman.txt packages/aur.txt scripts/10-packages.sh
git commit -m "feat(setup): pacman + AUR package lists and install phase"
```

---

## Task 6: Symlinks manifest + symlinks phase

**Files:**
- Create: `symlinks.txt`
- Create: `scripts/20-symlinks.sh`

- [ ] **Step 1: Write `symlinks.txt`**

Format: `<repo-relative-src>|<home-relative-dest>`, one per line, `#` comments allowed.

```
# source (relative to repo root) | dest (relative to $HOME)
hypr|.config/hypr
kitty|.config/kitty
quickshell|.config/quickshell
nvim|.config/nvim
tmux|.config/tmux
qt6ct|.config/qt6ct
Kvantum|.config/Kvantum
gtk-3.0|.config/gtk-3.0
gtk-4.0|.config/gtk-4.0
btop|.config/btop
zsh/.zshrc|.zshrc
zsh/.zshenv|.zshenv
zsh/starship.toml|.config/starship.toml
claude/settings.json|.claude/settings.json
claude/statusline-command.sh|.claude/statusline-command.sh
applications/kitty-nvim.desktop|.local/share/applications/kitty-nvim.desktop
quickshellsettings.toml|.config/quickshellsettings.toml
```

Note: `zsh/.zshenv` must exist in the repo — it was reported present by `ls zsh/`. Ditto `.zshrc`.

- [ ] **Step 2: Write `scripts/20-symlinks.sh`**

```bash
#!/usr/bin/env bash
# Phase 20 — create dotfile symlinks per symlinks.txt.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

manifest="$JIMDOTS_REPO/symlinks.txt"
[[ -f "$manifest" ]] || die "missing $manifest"

while IFS='|' read -r src dest; do
    # trim whitespace, skip blanks and comments
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

ok "symlinks applied"
```

- [ ] **Step 3: Make executable + syntax check**

```bash
chmod +x scripts/20-symlinks.sh
bash -n scripts/20-symlinks.sh
```

- [ ] **Step 4: Dry-run verification**

Run: `./setup.sh --only symlinks --dry-run`
Expected: logs `ln -sfn ...` or `link ok` lines for each entry, no filesystem changes. If an entry reports "source missing", fix the repo path or remove the entry.

- [ ] **Step 5: Real run (on current machine — should be all no-ops since links exist)**

Run: `./setup.sh --only symlinks`
Expected: each line reports `link ok: ...` with no backups taken (since existing links already point at the repo). If any `.bak.*` file is created unexpectedly, investigate before continuing.

- [ ] **Step 6: Commit**

```bash
git add symlinks.txt scripts/20-symlinks.sh
git commit -m "feat(setup): symlink manifest + phase"
```

---

## Task 7: Capture `/etc` files into repo

**Files:**
- Create: `etc/greetd/config.toml`
- Create: `etc/vconsole.conf`
- Create: `etc/tty-colors.pal`
- Create: `etc/systemd/system/tty-colors.service`
- Create: `etc/systemd/sleep.conf.d/hibernate.conf`

- [ ] **Step 1: Capture existing `/etc` files**

Run:

```bash
sudo cp /etc/greetd/config.toml etc/greetd/config.toml
sudo cp /etc/vconsole.conf etc/vconsole.conf
sudo cp /etc/tty-colors.pal etc/tty-colors.pal
sudo cp /etc/systemd/system/tty-colors.service etc/systemd/system/tty-colors.service
sudo chown "$USER":"$USER" etc/greetd/config.toml etc/vconsole.conf etc/tty-colors.pal etc/systemd/system/tty-colors.service
```

Expected: all four files now exist in the repo with user ownership.

- [ ] **Step 2: Author `etc/systemd/sleep.conf.d/hibernate.conf`**

This file doesn't exist on the current system — we create it from the spec:

```ini
[Sleep]
HibernateDelaySec=2h
```

Write to `etc/systemd/sleep.conf.d/hibernate.conf`.

- [ ] **Step 3: Verify captures look sensible**

Run: `head -5 etc/greetd/config.toml etc/vconsole.conf etc/tty-colors.pal etc/systemd/system/tty-colors.service etc/systemd/sleep.conf.d/hibernate.conf`
Expected: each file has plausible content matching `tasks.md` descriptions. Redact or edit anything host-specific if present (none expected, but verify).

- [ ] **Step 4: Commit**

```bash
git add etc/
git commit -m "feat(setup): capture system etc files into repo"
```

---

## Task 8: System phase (`scripts/30-system.sh`)

**Files:**
- Create: `scripts/30-system.sh`

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Phase 30 — install /etc files, mkinitcpio resume hook, i2c group/module,
# print bootloader instructions (if hibernate enabled).
set -euo pipefail
. "$(dirname "$0")/lib.sh"
load_machine_conf

info "installing /etc files"
copy_etc etc/greetd/config.toml /etc/greetd/config.toml 644
copy_etc etc/vconsole.conf /etc/vconsole.conf 644
copy_etc etc/tty-colors.pal /etc/tty-colors.pal 644
copy_etc etc/systemd/system/tty-colors.service /etc/systemd/system/tty-colors.service 644

if [[ "${ENABLE_HIBERNATE:-0}" == "1" ]]; then
    copy_etc etc/systemd/sleep.conf.d/hibernate.conf /etc/systemd/sleep.conf.d/hibernate.conf 644
fi

info "configuring i2c (DDC brightness)"
if ! getent group i2c >/dev/null; then
    sudo_run groupadd -f i2c
fi
if ! id -nG "$USER" | tr ' ' '\n' | grep -qx i2c; then
    sudo_run usermod -aG i2c "$USER"
    warn "added $USER to group i2c — log out/in to pick it up"
fi
if ! id -nG "$USER" | tr ' ' '\n' | grep -qx video; then
    sudo_run usermod -aG video "$USER"
fi

sudo_run modprobe i2c-dev || true
if ! sudo grep -qxF i2c-dev /etc/modules-load.d/i2c-dev.conf 2>/dev/null; then
    sudo_run bash -c 'printf "i2c-dev\n" > /etc/modules-load.d/i2c-dev.conf'
fi

if [[ "${ENABLE_HIBERNATE:-0}" == "1" ]]; then
    info "ensuring resume hook in /etc/mkinitcpio.conf"
    if ! sudo grep -E '^HOOKS=.*\bresume\b' /etc/mkinitcpio.conf >/dev/null; then
        warn "inserting resume hook before filesystems in mkinitcpio.conf"
        sudo_run sed -i.bak -E 's/(^HOOKS=\([^)]*)\bfilesystems\b/\1resume filesystems/' /etc/mkinitcpio.conf
        sudo_run mkinitcpio -P
    else
        ok "mkinitcpio resume hook already present"
    fi

    if [[ -n "${SWAP_UUID:-}" ]]; then
        # Detect bootloader and print required cmdline
        if [[ -d /boot/loader/entries ]]; then
            loader_dir=/boot/loader/entries
            entry="$(ls -1 "$loader_dir"/*.conf 2>/dev/null | head -n1 || true)"
            warn "systemd-boot detected. Add to options line in $entry (or your default entry):"
            warn "    resume=UUID=$SWAP_UUID"
        elif [[ -f /etc/default/grub ]]; then
            warn "GRUB detected. Edit /etc/default/grub GRUB_CMDLINE_LINUX_DEFAULT to include:"
            warn "    resume=UUID=$SWAP_UUID"
            warn "then run: sudo grub-mkconfig -o /boot/grub/grub.cfg"
        else
            warn "unknown bootloader — ensure your kernel cmdline includes: resume=UUID=$SWAP_UUID"
        fi
    else
        warn "ENABLE_HIBERNATE=1 but SWAP_UUID empty — skipping bootloader hint"
    fi
fi

ok "system configuration complete"
```

- [ ] **Step 2: Make executable + syntax check**

```bash
chmod +x scripts/30-system.sh
bash -n scripts/30-system.sh
```

- [ ] **Step 3: Dry-run**

Run: `./setup.sh --only system --dry-run`
Expected: logs `install -Dm644 ... /etc/...` lines with "etc up-to-date" for files that already match, and warns about bootloader + group membership appropriately. No actual changes.

- [ ] **Step 4: Commit**

```bash
git add scripts/30-system.sh
git commit -m "feat(setup): system phase — /etc files, mkinitcpio, i2c, bootloader hint"
```

---

## Task 9: Services phase (`scripts/40-services.sh`)

**Files:**
- Create: `scripts/40-services.sh`

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Phase 40 — enable systemd services (system + user).
set -euo pipefail
. "$(dirname "$0")/lib.sh"

SYSTEM_SERVICES=(tty-colors.service greetd.service bluetooth.service)
USER_SERVICES=(hypridle.service pipewire.service pipewire-pulse.service wireplumber.service)

info "reloading systemd"
sudo_run systemctl daemon-reload
run systemctl --user daemon-reload || true

for s in "${SYSTEM_SERVICES[@]}"; do
    if ! systemctl list-unit-files "$s" --no-legend --quiet 2>/dev/null | grep -q .; then
        warn "system unit $s not installed — skipping"
        continue
    fi
    sudo_run systemctl enable --now "$s"
done

for s in "${USER_SERVICES[@]}"; do
    if ! systemctl --user list-unit-files "$s" --no-legend --quiet 2>/dev/null | grep -q .; then
        warn "user unit $s not installed — skipping"
        continue
    fi
    run systemctl --user enable --now "$s"
done

ok "services enabled"
```

- [ ] **Step 2: Make executable + syntax check**

```bash
chmod +x scripts/40-services.sh
bash -n scripts/40-services.sh
```

- [ ] **Step 3: Dry-run**

Run: `./setup.sh --only services --dry-run`
Expected: logs `systemctl enable --now ...` for each service; no actual enabling.

- [ ] **Step 4: Commit**

```bash
git add scripts/40-services.sh
git commit -m "feat(setup): services phase — system + user systemctl enables"
```

---

## Task 10: Post phase (`scripts/50-post.sh`)

**Files:**
- Create: `scripts/50-post.sh`

- [ ] **Step 1: Write the script**

```bash
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
```

- [ ] **Step 2: Make executable + syntax check**

```bash
chmod +x scripts/50-post.sh
bash -n scripts/50-post.sh
```

- [ ] **Step 3: Dry-run**

Run: `./setup.sh --only post --dry-run`
Expected: logs submodule update, TPM clone (or skipped), theme-sync bootstraps, polkit build steps; no changes.

- [ ] **Step 4: Commit**

```bash
git add scripts/50-post.sh
git commit -m "feat(setup): post phase — submodules, TPM, git identity, theme-sync, chsh"
```

---

## Task 11: NVIDIA phase (`scripts/60-nvidia.sh`)

**Files:**
- Create: `scripts/60-nvidia.sh`

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Phase 60 — optional NVIDIA setup (detect + prompt).
set -euo pipefail
. "$(dirname "$0")/lib.sh"

if ! lspci | grep -qi nvidia; then
    log "no NVIDIA GPU detected — skipping"
    exit 0
fi

info "NVIDIA GPU detected"
if ! confirm "Run setup-nvidia.sh now?" n; then
    warn "skipping NVIDIA setup at user's request"
    exit 0
fi

script="$JIMDOTS_REPO/setup-nvidia.sh"
[[ -x "$script" ]] || die "setup-nvidia.sh missing or not executable"
run bash "$script"
ok "NVIDIA setup complete"
```

- [ ] **Step 2: Make executable + syntax check**

```bash
chmod +x scripts/60-nvidia.sh
bash -n scripts/60-nvidia.sh
```

- [ ] **Step 3: Dry-run**

Run: `./setup.sh --only nvidia --dry-run`
Expected on current NVIDIA machine: detection triggers prompt; declining (or `--yes` auto-accepts; for dry-run, the subshell logs the `bash setup-nvidia.sh` but doesn't execute). Verify log line.

- [ ] **Step 4: Commit**

```bash
git add scripts/60-nvidia.sh
git commit -m "feat(setup): nvidia phase — detect + prompt"
```

---

## Task 12: End-to-end smoke test and README section

**Files:**
- Modify: (none new) — end-to-end run validates the plan.
- Optionally add usage hint to `tasks.md`.

- [ ] **Step 1: Full dry-run**

Run: `./setup.sh --dry-run --yes`
Expected: executes every phase in order, prints actions but makes no changes, exits 0. Review `~/.cache/jimdots-setup.log` and look for `warn` / `err` lines. Fix any issues found before proceeding.

- [ ] **Step 2: Real idempotent run on current machine**

Run: `./setup.sh --yes`
Expected: packages already installed → `-Qi` quick; symlinks already present → `link ok`; `/etc` files identical → `etc up-to-date`; services already enabled → `systemctl enable` is a no-op; submodule init succeeds. No `.bak.*` files should be created.

Verify afterward:

```bash
ls ~/.config/hypr ~/.config/quickshell   # are still symlinks into jimdots
find ~ -maxdepth 3 -name '*.bak.*' -newer setup.sh 2>/dev/null  # should be empty
tail -50 ~/.cache/jimdots-setup.log
```

- [ ] **Step 3: Add a short section to `tasks.md`**

Append near the top (under "Arch Hyprland Setup"):

```markdown
## Reinstalling from scratch
Run `./setup.sh` from the repo root. Use `--dry-run` first on unfamiliar machines.
See `docs/superpowers/specs/2026-04-15-setup-script-design.md` for design details.
```

- [ ] **Step 4: Commit**

```bash
git add tasks.md
git commit -m "docs: mention setup.sh in tasks.md"
```

- [ ] **Step 5: Final verification**

Run: `./setup.sh --help`
Expected: usage output matches what's documented.

---

## Self-review

**Spec coverage check:**
- ✅ Orchestrator + phase scripts (Task 2-3, 4-11)
- ✅ Idempotency via hybrid strategy (`safe_link`, `copy_etc`, `ensure_line`, native `--needed` / `--now`)
- ✅ `machine.local.conf` prompts and persistence (Task 4)
- ✅ Git identity skippable prompt (Task 4)
- ✅ NVIDIA detect-and-prompt (Task 11)
- ✅ `/etc` files captured into repo (Task 7)
- ✅ mkinitcpio resume hook insertion (Task 8)
- ✅ Bootloader cmdline printed, not auto-edited (Task 8)
- ✅ i2c group + module + user add (Task 8)
- ✅ Service enables (Task 9)
- ✅ Submodules, TPM, theme-sync, polkit build, chsh (Task 10)
- ✅ `--dry-run`, `--only`, `--yes`, `--help` (Task 3)
- ✅ Rollback limited to symlink `.bak` only (implemented in `safe_link`)

**Placeholder scan:** no TBDs, every code block is concrete.

**Type/naming consistency:**
- helpers: `log/info/ok/warn/die/run/sudo_run/confirm/prompt_default/is_pkg_installed/safe_link/copy_etc/ensure_line/sudo_ensure_line/load_machine_conf/save_machine_conf/dry` — used consistently across Tasks 4-11.
- env vars: `JIMDOTS_REPO`, `JIMDOTS_LOG`, `JIMDOTS_DRY_RUN`, `JIMDOTS_ASSUME_YES` — consistent.
- machine conf keys: `HOSTNAME GIT_NAME GIT_EMAIL SWAP_UUID DDC_BUS ENABLE_HIBERNATE` — consistent across preflight (Task 4), system (Task 8), post (Task 10).

No gaps or inconsistencies found.
