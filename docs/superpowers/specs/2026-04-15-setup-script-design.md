# Design: `jimdots` setup script

## Goal

A single-entry orchestrator that recreates Jim's Arch + Hyprland + Quickshell
desktop from the `jimdots` repo — packages, dotfile symlinks, `/etc` files,
systemd services, submodules, and post-setup bootstraps — and is safe to
re-run on any machine to reconcile state.

## Scope

**In scope**
- Arch pacman packages and AUR packages (via `yay`)
- Dotfile symlinks (`~/.config/*`, `~/.zshrc`, etc.)
- System files under `/etc` (greetd, vconsole, tty-colors, hibernate)
- `mkinitcpio` resume hook insertion
- i2c group + module for DDC brightness
- systemd service enables (system + user)
- Git submodule init (`quill-polkit`)
- TPM clone + plugin install
- Browser theme-sync bootstraps (Zen, Firefox)
- Optional NVIDIA driver setup (detect + prompt)
- Git identity prompt (skippable)
- Default shell switch to zsh

**Out of scope**
- Personal data: Zen/Firefox profiles, SSH keys, GPG keys
- Secrets: `.env`, API tokens, `~/.claude.json` credentials
- User-specific Claude data: `~/.claude/projects/`, memory
- Bootloader cmdline edits (GRUB / systemd-boot): printed instructions, never auto-edited
- LazyVim plugin install (bootstraps on first `nvim`)
- Distros other than Arch

## Target scenarios

1. **Fresh Arch install** (base + networking only) → one `./setup.sh` run brings
   the machine to full desktop parity.
2. **Re-provision / idempotent sync** on an existing machine → same command is
   safe to re-run after `jimdots` changes; unchanged steps are no-ops.

## Architecture

```
jimdots/
├── setup.sh                  # orchestrator
├── scripts/
│   ├── lib.sh                # log/confirm/link/idempotency helpers
│   ├── 00-preflight.sh       # arch check, sudo keepalive, yay bootstrap, prompts
│   ├── 10-packages.sh        # pacman + AUR from packages/*.txt
│   ├── 20-symlinks.sh        # links from symlinks.txt
│   ├── 30-system.sh          # /etc files, mkinitcpio, groups, modules
│   ├── 40-services.sh        # systemctl enables (system + user)
│   ├── 50-post.sh            # submodules, TPM, polkit build, theme-sync, chsh
│   └── 60-nvidia.sh          # detect + prompt + delegate
├── packages/
│   ├── pacman.txt
│   └── aur.txt
├── symlinks.txt              # "<repo-relative-src>|<home-relative-dest>"
├── etc/
│   ├── greetd/config.toml
│   ├── vconsole.conf
│   ├── tty-colors.pal
│   ├── systemd/system/tty-colors.service
│   └── systemd/sleep.conf.d/hibernate.conf
└── machine.local.conf        # gitignored: HOSTNAME, GIT_NAME, GIT_EMAIL,
                              #            SWAP_UUID, DDC_BUS, ENABLE_HIBERNATE
```

## Orchestrator CLI

- `./setup.sh` — run all phases in order
- `./setup.sh --only symlinks` or `--only packages,system` — subset
- `./setup.sh --dry-run` — print actions, change nothing
- `./setup.sh --yes` — assume yes for prompts (except `machine.local.conf`
  value prompts, which must be answered or skipped explicitly)

Each phase script under `scripts/` is independently runnable.

## Idempotency strategy (hybrid)

Native-idempotent tools where available; explicit guards where not.

| Action | Strategy |
|---|---|
| Package install | `pacman -S --needed` / `yay -S --needed` |
| Symlink | `ln -sfn`, pre-existing non-symlinks moved to `*.bak.<ts>` |
| Service enable | `systemctl enable --now` |
| `/etc/*` file copy | `cmp -s` then `install -Dm644` only if differing |
| `mkinitcpio.conf` HOOKS | regex check; insert `resume` before `filesystems` only if absent |
| Kernel cmdline | never auto-edit; print required line + bootloader path |
| Group membership | `getent group i2c \| grep -qw $USER` before `usermod -aG` |
| Git submodule | `git submodule update --init --recursive` (natively idempotent) |
| TPM | `[ -d ~/.tmux/plugins/tpm ]` guard before clone |
| `chsh` | check `$SHELL` ends in `zsh` before changing |

## Phase contents

### 00-preflight
- Assert `/etc/arch-release`
- `sudo -v` + background keepalive (`while sleep 60; sudo -n true; done`)
- Network check: `ping -c1 archlinux.org`
- Ensure `base-devel git` installed
- Bootstrap `yay` from AUR if missing (`makepkg -si --noconfirm` in `/tmp`)
- Load or create `machine.local.conf`; prompt for missing keys
  (empty input = skip that feature):
  - `HOSTNAME` (optional)
  - `GIT_NAME`, `GIT_EMAIL` (optional)
  - `SWAP_UUID` (auto-detect via `findmnt` / `swapon --show --noheadings`, confirm)
  - `DDC_BUS` (run `ddcutil detect` if installed, parse, confirm)
  - `ENABLE_HIBERNATE` (y/n)

### 10-packages
- `pacman -S --needed --noconfirm $(grep -v '^#' packages/pacman.txt)`
- `yay -S --needed --noconfirm $(grep -v '^#' packages/aur.txt)` as non-root
- Lists seeded from the "Installed" section of `tasks.md`

### 20-symlinks
- For each `src|dest` in `symlinks.txt`:
  - `mkdir -p "$(dirname ~/dest)"`
  - If `~/dest` exists and is not already a symlink to our repo path: move to
    `~/dest.bak.<unix-ts>`
  - `ln -sfn "$REPO/src" "$HOME/dest"`
- Covers: `hypr`, `kitty`, `quickshell`, `nvim`, `tmux`, `qt6ct`, `Kvantum`,
  `gtk-3.0`, `gtk-4.0`, `btop`, `claude`, `applications/kitty-nvim.desktop`,
  `zsh/.zshrc` → `~/.zshrc`, `zsh/.zshenv` → `~/.zshenv`,
  `zsh/starship.toml` → `~/.config/starship.toml`

### 30-system
- `install -Dm644` the files under `etc/` into `/etc/` (skip if `cmp -s`)
- `mkinitcpio.conf`: insert `resume` hook before `filesystems` if missing;
  if inserted, run `mkinitcpio -P`
- Print required kernel cmdline addition
  (`resume=UUID=$SWAP_UUID`) + detected bootloader config path; do not auto-edit
- `groupadd -f i2c`; `usermod -aG i2c,video $USER` if not a member
- `modprobe i2c-dev`; ensure `i2c-dev` in `/etc/modules-load.d/i2c-dev.conf`

### 40-services
- `systemctl daemon-reload`
- System enables: `greetd.service`, `tty-colors.service`, `bluetooth.service`
- User enables: `hypridle.service`, `pipewire`, `pipewire-pulse`, `wireplumber`
- All via `enable --now` (natively idempotent)

### 50-post
- `git submodule update --init --recursive`
- Apply `git config --global user.name/user.email` if set
- TPM: clone to `~/.tmux/plugins/tpm` if absent; run `bin/install_plugins`
- Run `zen/setup-live-theme-sync.sh`
- If Firefox installed: run `firefox/setup-live-theme-sync.sh`
- Build/install `quill-polkit` from submodule if it has a `Makefile` or
  `install.sh`
- `chsh -s $(command -v zsh)` if current login shell isn't zsh
- Print reminder: run `nvim` once to bootstrap LazyVim plugins

### 60-nvidia
- If `lspci | grep -qi nvidia`:
  prompt "NVIDIA GPU detected. Run setup-nvidia.sh now? [y/N]"
- On yes: execute `./setup-nvidia.sh`
- Otherwise skip silently

## Logging and error handling

- `lib.sh` provides `log()`, `warn()`, `die()`, `confirm()`
- Every action logged to `~/.cache/jimdots-setup.log` with timestamps
- stdout gets colored output when `[[ -t 1 ]]`
- `set -euo pipefail` in every script
- On phase failure: orchestrator prints `phase NN failed — see log`, halts
- Re-run with `--only <phase>` after fixing the underlying issue

## Rollback — intentionally limited

- Symlink phase backs up pre-existing files to `*.bak.<ts>` (manually restorable)
- Package installs, service enables, `/etc` writes, `mkinitcpio` runs: no
  automated undo — idempotent re-run is the recovery mechanism
- Kernel cmdline never touched by the script, so no undo needed there
- `--dry-run` is the safety mechanism for unknown-state machines

## Files added to the repo

- `setup.sh` + `scripts/*.sh` + `scripts/lib.sh`
- `packages/pacman.txt`, `packages/aur.txt`
- `symlinks.txt`
- `etc/greetd/config.toml`, `etc/vconsole.conf`, `etc/tty-colors.pal`,
  `etc/systemd/system/tty-colors.service`,
  `etc/systemd/sleep.conf.d/hibernate.conf`
  (captured from the current working machine)
- `.gitignore` entry for `machine.local.conf`

## Non-goals / explicit exclusions

- No distro support beyond Arch
- No automated bootloader edits
- No secrets, profiles, or SSH/GPG keys
- No rollback of non-symlink actions
- No hot-reload of running shell/WM — reboot or re-login is expected after
  first run

## Open items addressed by prompts at runtime

- Swap UUID (hibernate) — auto-detected, user confirms
- DDC monitor bus — auto-detected via `ddcutil detect`, user confirms
- Git identity — optional, skippable
- NVIDIA setup — auto-detected hardware, user confirms
- Hibernate enable — explicit y/n
