# soydots

Personal Arch Linux dotfiles and system bootstrap. Ships a Hyprland +
Quickshell desktop, kitty + zsh + tmux shell stack, a Neovim config, and
everything needed to turn a fresh Arch install into the working setup.

## What's in here

```
hypr/                 Hyprland compositor config
quickshell/           Quickshell QML desktop shell (bar, launcher, settings)
nvim/                 Neovim config
kitty/ tmux/ zsh/     Terminal + shell stack (starship prompt)
btop/ gtk-*/ qt6ct/ Kvantum/
                      Theming (GTK 3/4, Qt, btop)
applications/         .desktop launchers
claude/               ~/.claude settings + statusline script
etc/                  System files copied into /etc (greetd, vconsole,
                      tty-colors service, sleep.conf)
fonts/ wallpapers/    Assets
firefox/ zen/         Browser tweaks
quill/ quickshell/icons/ quickshell/quill-polkit/
                      Git submodules (theme + polkit agent)

packages/packages.txt List of every package installed by phase 10
symlinks.txt          src|dest manifest consumed by phase 20
scripts/              Phase scripts (00-preflight … 60-nvidia) + lib.sh
setup.sh              Orchestrator — runs the phase scripts in order
setup-nvidia.sh       NVIDIA power-management udev rules (opt-in)
setup-stuff-mount.sh  Interactive fstab helper for extra partitions
machine.local.conf    Per-machine config (gitignored, created by preflight)
```

## Requirements

- Fresh Arch Linux install with network access
- A regular user with `sudo` privileges (don't run as root)
- ~15 min of attention for the interactive prompts in preflight

## Running `setup.sh`

The orchestrator runs a series of phase scripts under `scripts/`. Each
phase is idempotent — re-running is safe.

```sh
./setup.sh                         # full run, all phases in order
./setup.sh --only symlinks         # one phase
./setup.sh --only packages,system  # several phases
./setup.sh --dry-run               # print actions, change nothing
./setup.sh --yes                   # assume "yes" for confirm prompts
./setup.sh --help
```

Output is colourised on a TTY and also tee'd to `~/.cache/jimdots-setup.log`.

### Phases

Phases run in this order; `--only` accepts any subset.

| # | Phase       | Script              | What it does |
|---|-------------|---------------------|--------------|
| 00 | `preflight` | `00-preflight.sh`   | Verifies Arch + network, refreshes `sudo`, installs `base-devel`/`git`/`gum`, bootstraps `yay`, and prompts for machine config (hostname, git identity, DDC bus for brightness, hibernate toggle) into `machine.local.conf`. |
| 05 | `mirrors`   | `05-mirrors.sh`     | Tunes `/etc/pacman.conf` (Color, ParallelDownloads, multilib) and refreshes the mirrorlist via `reflector`. |
| 10 | `packages`  | `10-packages.sh`    | Installs everything in `packages/packages.txt` through `yay` (handles repo + AUR). |
| 20 | `symlinks`  | `20-symlinks.sh`    | Creates the dotfile symlinks listed in `symlinks.txt` (`src` relative to repo, `dest` relative to `$HOME`). Existing files get backed up. |
| 30 | `system`    | `30-system.sh`      | Installs files under `etc/` into `/etc/` (greetd, vconsole, tty-colors), adds the `i2c` group + module for DDC brightness, and wires up the `resume` hook in `mkinitcpio` if hibernate is enabled. |
| 40 | `services`  | `40-services.sh`    | Enables systemd units. System: `tty-colors`, `bluetooth` (started now), `greetd` (enabled only — starting it mid-setup would hijack the TTY). User: `hypridle`, `pipewire`, `pipewire-pulse`, `wireplumber` — `--now` only inside a live graphical session, otherwise enable-only. |
| 50 | `post`      | `50-post.sh`        | `git submodule update --init --recursive`, sets git identity from `machine.local.conf`, bootstraps tmux TPM, seeds `~/.config/tmux/quickshell-tmux.conf`, and `chsh`es to `zsh`. |
| 60 | `nvidia`    | `60-nvidia.sh`      | If an NVIDIA GPU is detected, offers to run `setup-nvidia.sh` (installs the power-management udev rules). Skipped otherwise. |

At the very end of a full run (no `--only`), setup offers a single
reboot so greetd, group membership, and kernel params take effect.

## Per-machine config

Phase 00 writes `machine.local.conf` (gitignored) with the answers from
the preflight prompts:

```
HOSTNAME=...
GIT_NAME=...
GIT_EMAIL=...
DDC_BUS=...           # i2c bus used for external-monitor brightness
ENABLE_HIBERNATE=0|1  # drives sleep.conf + mkinitcpio resume hook
```

Later phases `source` this file. Re-run `--only preflight` to regenerate it.

## Extras

- **`setup-nvidia.sh`** — installs udev rules for NVIDIA runtime power
  management. Run directly or via phase 60.
- **`setup-stuff-mount.sh`** — interactive helper to add extra
  partitions to `/etc/fstab` with sane mount options. Independent of
  the main setup.
- **`test-notifs.sh`** — quick sanity check for desktop notifications.

## Reapplying after changes

After editing dotfiles just `git pull` — the symlinks keep the live
configs in sync. After adding a package to `packages/packages.txt`,
adding a symlink entry, or changing `/etc/` files, re-run the relevant
phase:

```sh
./setup.sh --only packages
./setup.sh --only symlinks
./setup.sh --only system
```
