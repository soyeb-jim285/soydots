# Design: Repo-name-agnostic runtime paths

## Problem

Runtime code across the repo hardcodes `~/jimdots/...` or `/home/jim/jimdots/...`
as the repo location. The GitHub repo is named `soydots`; a fresh clone using
the GitHub default (`soydots`), or any other folder name, breaks wallpapers,
brightness hotkeys, screenshot binds, quickshell theme writes, hypridle
actions, and more.

Scope is **runtime paths only** — branding text (log filenames, setup banner,
UI labels, JS global names, extension IDs) and historical doc references are
out of scope.

## Goal

After the change, cloning the repo to any directory (e.g. `~/soydots`,
`~/dotfiles`, `/opt/jim`) and running `setup.sh` produces a fully working
desktop. No repo-name assumptions remain in runtime code.

## Approach

**Symlink-relative paths wherever possible; self-resolution where not.** No
env vars, no setup-time file rewriting, no template substitution.

### Why this mechanism

The `setup.sh` symlink phase already creates `~/.config/hypr`,
`~/.config/quickshell`, `~/.config/qt6ct`, etc. as symlinks into the repo.
Any runtime code that needs a file under one of those directories can
address it via `~/.config/<name>/...` — the symlink resolves to the real repo
location regardless of what the repo is called or where it lives.

For the handful of paths that point outside the symlinked tree
(`wallpapers/`, `tmux/write-quickshell-conf.py`), bash and Python can
self-resolve their own real location via `readlink -f` / `os.path.realpath`
and compute siblings relatively.

Alternatives rejected:

- **`$JIMDOTS_REPO` env var** — requires injecting the env into zsh, uwsm,
  hyprland, and quickshell. Any launcher that misses it breaks silently.
- **Setup-time path rewriting** — would dirty tracked files on every
  `setup.sh` run and require templating infrastructure.

## Per-file changes

### Bash scripts in `hypr/`

Nine scripts reference siblings via absolute `/home/jim/jimdots/hypr/...`:
`external-brightness.sh`, `brightness-key.sh`, `brightness-sync.sh`,
`idle-dim.sh`, `idle-undim.sh`, `idle-dpms-on.sh`, `idle-dpms-off.sh`,
`idle-after-sleep.sh`, plus `gen-wallpaper.sh` (which additionally needs the
repo root for `wallpapers/`).

Standard prelude inserted near the top of each:

```bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
```

Then `/home/jim/jimdots/hypr/sibling.sh` → `"$SCRIPT_DIR/sibling.sh"`.

For `gen-wallpaper.sh` specifically, also:

```bash
WALLPAPER_DIR="$(dirname "$SCRIPT_DIR")/wallpapers"
SETTINGS="$HOME/.config/quickshellsettings.toml"   # already symlinked
```

Scripts invoked via the `~/.config/hypr` symlink still get the real repo
path because `readlink -f` resolves through symlinks.

### Hypr configs

`hypr/hyprland.conf` (five binds at lines 276–278, 340–341) and
`hypr/hypridle.conf` (five hook commands) — replace every occurrence of
`~/jimdots/hypr/X.sh` and `/home/jim/jimdots/hypr/X.sh` with
`~/.config/hypr/X.sh`. Both Hyprland and hypridle expand `~`, so this is a
straight swap.

### QML

Every runtime path in `Config.qml`, `IdleManager.qml`, and
`NotificationCenter.qml` targets a file that is already symlinked under
`~/.config/`, with one exception. Swap `_homeDir + "/jimdots/<dir>/<file>"`
to the equivalent config-tree path:

| Before | After |
|---|---|
| `/jimdots/kitty/current-theme.conf` | `/.config/kitty/current-theme.conf` |
| `/jimdots/hypr/quickshell-theme.conf` | `/.config/hypr/quickshell-theme.conf` |
| `/jimdots/hypr/gen-wallpaper.sh` | `/.config/hypr/gen-wallpaper.sh` |
| `/jimdots/hypr/hyprland.conf` | `/.config/hypr/hyprland.conf` |
| `/jimdots/hypr/hypridle.conf` | `/.config/hypr/hypridle.conf` |
| `/jimdots/hypr/screenshot.sh` | `/.config/hypr/screenshot.sh` |
| `/jimdots/hypr/brightness-sync.sh` | `/.config/hypr/brightness-sync.sh` |
| `/jimdots/hypr/idle-*.sh` (written into hypridle.conf) | `/.config/hypr/idle-*.sh` |
| `/jimdots/zsh/starship.toml` | `/.config/starship.toml` |
| `/jimdots/btop/themes/<file>` | `/.config/btop/themes/<file>` |
| `/jimdots/qt6ct/colors/<file>` | `/.config/qt6ct/colors/<file>` |
| `/jimdots/gtk-3.0/settings.ini` | `/.config/gtk-3.0/settings.ini` |
| `/jimdots/gtk-4.0/settings.ini` | `/.config/gtk-4.0/settings.ini` |
| `/jimdots/tmux/write-quickshell-conf.py` | `/.config/tmux/write-quickshell-conf.py` (see below) |

The `IdleManager.qml` paths (lines 48, 55–56, 72–73) deserve attention:
those strings are written *into* `hypridle.conf`, so they must be valid
paths the hypridle daemon can exec. `~/.config/hypr/idle-*.sh` works —
hypridle expands `~`.

### `tmux/write-quickshell-conf.py`

Two changes:

1. **Add to `symlinks.txt`**:
   `tmux/write-quickshell-conf.py|.config/tmux/write-quickshell-conf.py`
   so `Config.qml:832` can reference it via `_homeDir + "/.config/tmux/..."`.
2. **In the script itself** (line 57), replace
   `os.path.expanduser("~/jimdots/tmux")` with
   `os.path.dirname(os.path.realpath(__file__))`.

### `qt6ct/qt6ct.conf`

Line 2: `color_scheme_path=/home/jim/jimdots/qt6ct/colors/catppuccin-mocha.conf`.

qt6ct does not expand `~` or `$HOME` in this field — it stores an absolute
path verbatim. `Config.qml` already rewrites this file on every theme sync
(via the write at line 655), so the tracked value is already transient
state — whoever ran quickshell last wrote it.

Two one-line changes are enough:

1. **`Config.qml` line 655** — rewrite the computed path to
   `_homeDir + "/.config/qt6ct/colors/" + qtColorFile`. From then on, every
   theme-sync pass writes a repo-name-agnostic path.
2. **Tracked `qt6ct/qt6ct.conf`** — update the checked-in
   `color_scheme_path` to use the `.config` form (still absolute, still
   hardcodes `/home/jim/` for historical reasons — a fresh user will see
   whatever theme Jim last wrote for ~1s until Config.qml's startup sync
   overwrites it with the correct path).

Acceptable trade-off: this pre-existing issue (Jim's `$HOME` baked into a
tracked file) is not the repo-name problem we're solving. Punt on it.

## Ordering and testing

Each file change is independent. A sensible sequence:

1. Bash scripts — can be tested in isolation by running each from a terminal.
2. Hypr configs — reload hyprland, verify binds still work.
3. Python + `symlinks.txt` addition — re-run `setup.sh --only symlinks`, exec
   the script.
4. QML — requires a quickshell restart to pick up changes.
5. `qt6ct.conf` — last, since it's the most finicky and relies on Config.qml
   landing first.

## Verification

- Rename `~/jimdots` to `~/test-soydots` temporarily (or clone fresh into a
  differently-named directory), re-run `setup.sh`, and confirm:
  - Wallpaper loads at login
  - Screenshot binds (`SUPER+SHIFT+P/F/W`) work
  - External-brightness hotkeys (`SUPER+F5/F6`) work
  - Theme toggle rewrites hyprland border colors, starship, btop, qt6ct
  - Idle dim / undim / dpms transitions fire
- Grep the repo for `jimdots` references and confirm no matches remain in
  any runtime file (bash scripts, QML, Python, `.conf` files).
