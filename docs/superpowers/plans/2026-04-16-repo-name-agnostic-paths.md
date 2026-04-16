# Repo-name-agnostic Runtime Paths Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove every hardcoded `~/jimdots/` and `/home/jim/jimdots/` reference from runtime code so the repo works when cloned under any folder name (e.g. `soydots` on GitHub, or any user-chosen directory).

**Architecture:** Two-pronged approach with no coordination infrastructure. (1) For files reachable via the `~/.config/` symlink tree (hypr, quickshell, kitty, qt6ct, btop, gtk, starship, tmux.conf, quickshellsettings.toml) — address via `~/.config/...`. (2) For bash scripts and the Python helper — self-resolve via `readlink -f "$0"` / `os.path.realpath(__file__)`.

**Tech Stack:** Bash, Hyprland config, hypridle config, QML (Quickshell), Python, qt6ct config. No new dependencies. No tests (dotfiles repo has no test suite); verification is grep + smoke-test.

**Spec:** `docs/superpowers/specs/2026-04-16-repo-name-agnostic-paths-design.md`

---

## Task 1: Add SCRIPT_DIR prelude to sibling-calling bash scripts

**Files:**
- Modify: `hypr/external-brightness.sh`
- Modify: `hypr/brightness-key.sh`
- Modify: `hypr/brightness-sync.sh`
- Modify: `hypr/idle-dim.sh`
- Modify: `hypr/idle-undim.sh`
- Modify: `hypr/idle-dpms-on.sh`
- Modify: `hypr/idle-dpms-off.sh`
- Modify: `hypr/idle-after-sleep.sh`

All eight scripts reference sibling scripts in `hypr/` via absolute `/home/jim/jimdots/hypr/X.sh`. Each gets the same one-line prelude inserted after any existing `set -e` line (or after the shebang if none), and their sibling calls swapped to `"$SCRIPT_DIR/X.sh"`.

- [ ] **Step 1: Add prelude + fix calls in `hypr/external-brightness.sh`**

Read the file first to find the exact location. The file currently has one self-reference at line 84:
```bash
  nohup /home/jim/jimdots/hypr/external-brightness.sh apply >/dev/null 2>&1 &
```

Insert after the shebang + any `set -*` line:
```bash
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
```

Replace the self-reference:
```bash
  nohup "$SCRIPT_DIR/external-brightness.sh" apply >/dev/null 2>&1 &
```

- [ ] **Step 2: Fix `hypr/brightness-key.sh`**

Line 5 currently:
```bash
/home/jim/jimdots/hypr/brightness-sync.sh "$@"
```

Add the same prelude near the top and replace line 5 with:
```bash
"$SCRIPT_DIR/brightness-sync.sh" "$@"
```

- [ ] **Step 3: Fix `hypr/brightness-sync.sh`**

Lines 17, 19, 22, 26 all call `external-brightness.sh` via absolute path. Add the prelude and replace each `/home/jim/jimdots/hypr/external-brightness.sh` with `"$SCRIPT_DIR/external-brightness.sh"`. There are four call sites — all get the same swap.

- [ ] **Step 4: Fix `hypr/idle-dim.sh`**

Lines 12 and 14 reference `external-brightness.sh`. Add prelude; swap both occurrences to `"$SCRIPT_DIR/external-brightness.sh"`.

- [ ] **Step 5: Fix `hypr/idle-undim.sh`**

Line 11 references `external-brightness.sh`. Add prelude; swap to `"$SCRIPT_DIR/external-brightness.sh"`.

- [ ] **Step 6: Fix `hypr/idle-dpms-on.sh`**

Line 5 references `external-brightness.sh`. Add prelude; swap to `"$SCRIPT_DIR/external-brightness.sh"`.

- [ ] **Step 7: Fix `hypr/idle-dpms-off.sh`**

Line 6 references `external-brightness.sh`. Add prelude; swap to `"$SCRIPT_DIR/external-brightness.sh"`.

- [ ] **Step 8: Fix `hypr/idle-after-sleep.sh`**

Lines 5 and 6 reference `idle-dpms-on.sh` and `idle-undim.sh`. Add prelude; swap both to `"$SCRIPT_DIR/idle-dpms-on.sh"` and `"$SCRIPT_DIR/idle-undim.sh"`.

- [ ] **Step 9: Verify no `jimdots` references remain in these 8 files**

Run:
```bash
grep -n jimdots hypr/external-brightness.sh hypr/brightness-key.sh hypr/brightness-sync.sh hypr/idle-dim.sh hypr/idle-undim.sh hypr/idle-dpms-on.sh hypr/idle-dpms-off.sh hypr/idle-after-sleep.sh
```
Expected: no output (exit code 1).

- [ ] **Step 10: Smoke-test one script**

Run:
```bash
bash -n hypr/external-brightness.sh hypr/brightness-key.sh hypr/brightness-sync.sh hypr/idle-dim.sh hypr/idle-undim.sh hypr/idle-dpms-on.sh hypr/idle-dpms-off.sh hypr/idle-after-sleep.sh
```
Expected: no syntax errors, exit 0.

- [ ] **Step 11: Commit**

```bash
git add hypr/external-brightness.sh hypr/brightness-key.sh hypr/brightness-sync.sh hypr/idle-dim.sh hypr/idle-undim.sh hypr/idle-dpms-on.sh hypr/idle-dpms-off.sh hypr/idle-after-sleep.sh
git commit -m "refactor(hypr): self-resolve sibling script paths via readlink

Replace hardcoded /home/jim/jimdots/hypr/ absolute paths with
\$SCRIPT_DIR-relative invocations so scripts work regardless of
where the repo is cloned."
```

---

## Task 2: Fix `hypr/gen-wallpaper.sh` to locate repo root via self

**Files:**
- Modify: `hypr/gen-wallpaper.sh`

Currently hardcodes `$HOME/jimdots/wallpapers` and `$HOME/jimdots/quickshellsettings.toml`. After this task, it resolves both relative to itself.

- [ ] **Step 1: Update the two hardcoded paths**

Current lines 8 and 13:
```bash
WALLPAPER_DIR="$HOME/jimdots/wallpapers"
# ...
SETTINGS="$HOME/jimdots/quickshellsettings.toml"
```

Replace the `WALLPAPER_DIR` line with a script-relative lookup:
```bash
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
WALLPAPER_DIR="$(dirname "$SCRIPT_DIR")/wallpapers"
```

Replace the `SETTINGS` line with the symlinked path:
```bash
    SETTINGS="$HOME/.config/quickshellsettings.toml"
```

(Keep its indentation — it's inside an `if` block.)

- [ ] **Step 2: Verify**

Run:
```bash
grep -n jimdots hypr/gen-wallpaper.sh
```
Expected: no output.

Run:
```bash
bash -n hypr/gen-wallpaper.sh
```
Expected: no syntax errors.

- [ ] **Step 3: Smoke-test the wallpaper lookup path**

Run:
```bash
bash -c '
  SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$HOME/.config/hypr/gen-wallpaper.sh")")" && pwd)"
  WALLPAPER_DIR="$(dirname "$SCRIPT_DIR")/wallpapers"
  echo "$WALLPAPER_DIR"
  ls "$WALLPAPER_DIR"/end4-dark.png "$WALLPAPER_DIR"/end4-light.png
'
```
Expected: prints the repo's `wallpapers` path, both PNGs listed.

- [ ] **Step 4: Commit**

```bash
git add hypr/gen-wallpaper.sh
git commit -m "refactor(wallpaper): resolve wallpaper dir relative to script path

gen-wallpaper.sh now finds repo root via readlink instead of assuming
the repo lives at \$HOME/jimdots. Settings file switched to the
symlinked ~/.config/quickshellsettings.toml location."
```

---

## Task 3: Fix `hypr/hyprland.conf` binds

**Files:**
- Modify: `hypr/hyprland.conf`

Five bind lines hardcode repo paths. All are replaced with the `~/.config/hypr/` symlinked form. Hyprland shells out for `exec` commands, so `~` expansion works.

- [ ] **Step 1: Swap the three screenshot binds**

Lines 276–278 currently:
```
bind = $mainMod SHIFT, P, exec, ~/jimdots/hypr/screenshot.sh region
bind = $mainMod SHIFT, F, exec, ~/jimdots/hypr/screenshot.sh output
bind = $mainMod SHIFT, W, exec, ~/jimdots/hypr/screenshot.sh window
```

Change to:
```
bind = $mainMod SHIFT, P, exec, ~/.config/hypr/screenshot.sh region
bind = $mainMod SHIFT, F, exec, ~/.config/hypr/screenshot.sh output
bind = $mainMod SHIFT, W, exec, ~/.config/hypr/screenshot.sh window
```

- [ ] **Step 2: Swap the two brightness-key binds**

Lines 340–341 currently:
```
bindel = $mainMod, F6, exec, /home/jim/jimdots/hypr/brightness-key.sh set 5%+
bindel = $mainMod, F5, exec, /home/jim/jimdots/hypr/brightness-key.sh set 5%-
```

Change to:
```
bindel = $mainMod, F6, exec, ~/.config/hypr/brightness-key.sh set 5%+
bindel = $mainMod, F5, exec, ~/.config/hypr/brightness-key.sh set 5%-
```

- [ ] **Step 3: Verify**

Run:
```bash
grep -n jimdots hypr/hyprland.conf
```
Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add hypr/hyprland.conf
git commit -m "refactor(hypr): route script binds through ~/.config/hypr/

Screenshot and brightness binds no longer hardcode /home/jim/jimdots
or ~/jimdots; they go through the symlinked ~/.config/hypr path."
```

---

## Task 4: Fix `hypr/hypridle.conf` static hook paths

**Files:**
- Modify: `hypr/hypridle.conf`

This file is regenerated by `IdleManager.qml` at quickshell startup, but the tracked copy is what a fresh session reads before the regeneration fires. Fix both.

- [ ] **Step 1: Swap all five hook paths**

Lines 6, 11, 12, 22, 23 currently:
```
    after_sleep_cmd = /home/jim/jimdots/hypr/idle-after-sleep.sh
# ...
    on-timeout = /home/jim/jimdots/hypr/idle-dim.sh
    on-resume = /home/jim/jimdots/hypr/idle-undim.sh
# ...
    on-timeout = /home/jim/jimdots/hypr/idle-dpms-off.sh
    on-resume = /home/jim/jimdots/hypr/idle-dpms-on.sh
```

Change each `/home/jim/jimdots/hypr/` prefix to `~/.config/hypr/`. After the edit:
```
    after_sleep_cmd = ~/.config/hypr/idle-after-sleep.sh
# ...
    on-timeout = ~/.config/hypr/idle-dim.sh
    on-resume = ~/.config/hypr/idle-undim.sh
# ...
    on-timeout = ~/.config/hypr/idle-dpms-off.sh
    on-resume = ~/.config/hypr/idle-dpms-on.sh
```

- [ ] **Step 2: Verify**

Run:
```bash
grep -n jimdots hypr/hypridle.conf
```
Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add hypr/hypridle.conf
git commit -m "refactor(hypridle): use ~/.config/hypr/ for tracked hook paths"
```

---

## Task 5: Add tmux script to symlinks + self-resolve in Python

**Files:**
- Modify: `symlinks.txt`
- Modify: `tmux/write-quickshell-conf.py`

`Config.qml:832` references `tmux/write-quickshell-conf.py`, but `tmux/` isn't a directory-level symlink (only `tmux.conf` is). Adding the Python script to `symlinks.txt` lets Config.qml address it via `~/.config/tmux/...`. The script itself also needs to self-resolve its `src_dir`.

- [ ] **Step 1: Add entry to `symlinks.txt`**

After the existing `tmux/tmux.conf|.config/tmux/tmux.conf` line, append:
```
tmux/write-quickshell-conf.py|.config/tmux/write-quickshell-conf.py
```

- [ ] **Step 2: Self-resolve in the Python script**

Line 57 of `tmux/write-quickshell-conf.py` currently:
```python
src_dir = os.path.expanduser("~/jimdots/tmux")
```

Change to:
```python
src_dir = os.path.dirname(os.path.realpath(__file__))
```

`os.path.realpath` resolves through the symlink from `~/.config/tmux/write-quickshell-conf.py` back to the real repo file, so `dirname` yields the repo's `tmux/` dir.

- [ ] **Step 3: Materialize the new symlink**

Run:
```bash
./setup.sh --only symlinks
```
Expected: output includes a `link` action creating `~/.config/tmux/write-quickshell-conf.py`. No errors.

- [ ] **Step 4: Verify the symlink works**

Run:
```bash
readlink -f ~/.config/tmux/write-quickshell-conf.py
```
Expected: absolute path ending in `tmux/write-quickshell-conf.py` pointing back into the repo.

- [ ] **Step 5: Verify script still works when invoked via symlink**

Run:
```bash
python3 -c "
import os
p = os.path.expanduser('~/.config/tmux/write-quickshell-conf.py')
src_dir = os.path.dirname(os.path.realpath(p))
print(src_dir)
assert os.path.isdir(src_dir), src_dir
print('OK')
"
```
Expected: prints repo tmux dir, then `OK`.

- [ ] **Step 6: Verify no `jimdots` in the Python script**

Run:
```bash
grep -n jimdots tmux/write-quickshell-conf.py
```
Expected: no output.

- [ ] **Step 7: Commit**

```bash
git add symlinks.txt tmux/write-quickshell-conf.py
git commit -m "refactor(tmux): symlink write-quickshell-conf.py + self-resolve src_dir

Add tmux/write-quickshell-conf.py to symlinks.txt so QML can reach it
via ~/.config/tmux. Script now uses realpath(__file__) to find its
own directory instead of assuming \$HOME/jimdots."
```

---

## Task 6: Fix `quickshell/NotificationCenter.qml`

**Files:**
- Modify: `quickshell/NotificationCenter.qml`

Two runtime-path strings: a bash `sleep && screenshot.sh` invocation and a direct `brightness-sync.sh` process command.

- [ ] **Step 1: Swap the screenshot exec**

Line 153 currently:
```qml
    Process { id: ssProc; command: ["bash", "-c", "sleep 0.3 && ~/jimdots/hypr/screenshot.sh region"] }
```

Change to:
```qml
    Process { id: ssProc; command: ["bash", "-c", "sleep 0.3 && ~/.config/hypr/screenshot.sh region"] }
```

- [ ] **Step 2: Swap the brightness-sync command**

Line 162 currently:
```qml
        command: ["/home/jim/jimdots/hypr/brightness-sync.sh", "set", pct + "%"]
```

Change to:
```qml
        command: [Quickshell.env("HOME") + "/.config/hypr/brightness-sync.sh", "set", pct + "%"]
```

Note: the QML `Process.command` first element is not shell-expanded, so `~` would not work — use `Quickshell.env("HOME")` instead. Config.qml already uses this pattern (see `property string _homeDir: Quickshell.env("HOME")`).

- [ ] **Step 3: Verify**

Run:
```bash
grep -n jimdots quickshell/NotificationCenter.qml
```
Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add quickshell/NotificationCenter.qml
git commit -m "refactor(qs): route NotificationCenter scripts through ~/.config/hypr"
```

---

## Task 7: Fix `quickshell/IdleManager.qml`

**Files:**
- Modify: `quickshell/IdleManager.qml`

Six references. Five of them (lines 48, 55, 56, 72, 73) build strings that get *written into* `hypridle.conf`, so the replacement must be an absolute-ish path hypridle can exec (hypridle expands `~`). The sixth (line 100) is the path IdleManager.qml writes to.

- [ ] **Step 1: Swap all six occurrences**

For each of these strings:
| Line | Current | Replacement |
|---|---|---|
| 48 | `_homeDir + "/jimdots/hypr/idle-after-sleep.sh"` | `_homeDir + "/.config/hypr/idle-after-sleep.sh"` |
| 55 | `_homeDir + "/jimdots/hypr/idle-dim.sh"` | `_homeDir + "/.config/hypr/idle-dim.sh"` |
| 56 | `_homeDir + "/jimdots/hypr/idle-undim.sh"` | `_homeDir + "/.config/hypr/idle-undim.sh"` |
| 72 | `_homeDir + "/jimdots/hypr/idle-dpms-off.sh"` | `_homeDir + "/.config/hypr/idle-dpms-off.sh"` |
| 73 | `_homeDir + "/jimdots/hypr/idle-dpms-on.sh"` | `_homeDir + "/.config/hypr/idle-dpms-on.sh"` |
| 100 | `_homeDir + "/jimdots/hypr/hypridle.conf"` | `_homeDir + "/.config/hypr/hypridle.conf"` |

Because `_homeDir` is a literal absolute path from `Quickshell.env("HOME")`, the values written into `hypridle.conf` are absolute (`/home/<user>/.config/hypr/...`), which hypridle can exec directly.

- [ ] **Step 2: Verify**

Run:
```bash
grep -n jimdots quickshell/IdleManager.qml
```
Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add quickshell/IdleManager.qml
git commit -m "refactor(qs): IdleManager writes ~/.config/hypr paths into hypridle.conf"
```

---

## Task 8: Fix `quickshell/Config.qml`

**Files:**
- Modify: `quickshell/Config.qml`

Eleven references across multiple functional areas. All target files that live under the symlinked `~/.config/` tree, so every replacement follows the pattern `_homeDir + "/jimdots/<subdir>/..."` → `_homeDir + "/.config/<equivalent>/..."`.

- [ ] **Step 1: Swap kitty and hypr theme paths (lines ~372–373)**

Current:
```qml
    property string _kittyThemePath: _homeDir + "/jimdots/kitty/current-theme.conf"
    property string _hyprThemePath: _homeDir + "/jimdots/hypr/quickshell-theme.conf"
```

Replace with:
```qml
    property string _kittyThemePath: _homeDir + "/.config/kitty/current-theme.conf"
    property string _hyprThemePath: _homeDir + "/.config/hypr/quickshell-theme.conf"
```

- [ ] **Step 2: Swap wallpaper invocation (line ~439)**

Current:
```qml
        _wallpaperProc.command = ["bash", "-c", _homeDir + "/jimdots/hypr/gen-wallpaper.sh " + (darkMode ? "dark" : "light")];
```

Replace with:
```qml
        _wallpaperProc.command = ["bash", "-c", _homeDir + "/.config/hypr/gen-wallpaper.sh " + (darkMode ? "dark" : "light")];
```

- [ ] **Step 3: Swap starship path (line ~488)**

Current:
```qml
    property string _starshipPath: _homeDir + "/jimdots/zsh/starship.toml"
```

`zsh/starship.toml` is symlinked to `~/.config/starship.toml` per `symlinks.txt`. Replace with:
```qml
    property string _starshipPath: _homeDir + "/.config/starship.toml"
```

- [ ] **Step 4: Swap btop theme paths (lines ~551–552)**

Current:
```qml
        let theme = darkMode
            ? _homeDir + "/jimdots/btop/themes/catppuccin_mocha.theme"
            : _homeDir + "/jimdots/btop/themes/catppuccin_latte.theme";
```

Replace with:
```qml
        let theme = darkMode
            ? _homeDir + "/.config/btop/themes/catppuccin_mocha.theme"
            : _homeDir + "/.config/btop/themes/catppuccin_latte.theme";
```

- [ ] **Step 5: Swap qt6ct color-scheme path (line ~655)**

Current:
```qml
        let qtColorPath = _homeDir + "/jimdots/qt6ct/colors/" + qtColorFile;
```

Replace with:
```qml
        let qtColorPath = _homeDir + "/.config/qt6ct/colors/" + qtColorFile;
```

- [ ] **Step 6: Swap tmux conf-script path (line ~832)**

Current:
```qml
    property string _tmuxConfScript: _homeDir + "/jimdots/tmux/write-quickshell-conf.py"
```

Replace with:
```qml
    property string _tmuxConfScript: _homeDir + "/.config/tmux/write-quickshell-conf.py"
```

(This relies on the symlink added in Task 5.)

- [ ] **Step 7: Swap cursor-sync paths (lines ~1431–1433)**

Current:
```qml
        let gtk3Path = _homeDir + "/jimdots/gtk-3.0/settings.ini";
        let gtk4Path = _homeDir + "/jimdots/gtk-4.0/settings.ini";
        let hyprConf = _homeDir + "/jimdots/hypr/hyprland.conf";
```

Replace with:
```qml
        let gtk3Path = _homeDir + "/.config/gtk-3.0/settings.ini";
        let gtk4Path = _homeDir + "/.config/gtk-4.0/settings.ini";
        let hyprConf = _homeDir + "/.config/hypr/hyprland.conf";
```

- [ ] **Step 8: Verify**

Run:
```bash
grep -n jimdots quickshell/Config.qml
```
Expected: no output.

- [ ] **Step 9: Commit**

```bash
git add quickshell/Config.qml
git commit -m "refactor(qs): route Config.qml paths through ~/.config/

Theme paths (kitty, hypr, btop, qt6ct, starship), cursor sync
(gtk-3.0, gtk-4.0, hyprland.conf), wallpaper invocation, and tmux
conf script all go through the symlinked ~/.config/ tree instead of
hardcoding \$HOME/jimdots."
```

---

## Task 9: Fix static `qt6ct/qt6ct.conf` color_scheme_path

**Files:**
- Modify: `qt6ct/qt6ct.conf`

Current line 2:
```
color_scheme_path=/home/jim/jimdots/qt6ct/colors/catppuccin-mocha.conf
```

qt6ct does not expand `~` or `$HOME`, so the value must be absolute. This is a one-shot value only used until Config.qml's first theme-sync overwrites it (which now also targets `~/.config/qt6ct/...` thanks to Task 8 Step 5). Updating the tracked path to the `.config` form keeps the repo internally consistent; the `/home/jim/` prefix is a pre-existing user-specific artifact and out of this task's scope.

- [ ] **Step 1: Change the path**

Replace line 2 with:
```
color_scheme_path=/home/jim/.config/qt6ct/colors/catppuccin-mocha.conf
```

- [ ] **Step 2: Verify**

Run:
```bash
grep -n jimdots qt6ct/qt6ct.conf
```
Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add qt6ct/qt6ct.conf
git commit -m "refactor(qt6ct): point color_scheme_path at ~/.config/ (via symlink)

Config.qml overwrites this at theme sync, but align the tracked
value with the new convention so first boot is internally
consistent."
```

---

## Task 10: Repo-wide verification

**Files:**
- No changes; verification only.

- [ ] **Step 1: Grep for any remaining runtime `jimdots` references**

Run:
```bash
grep -rn 'jimdots' \
  hypr/ quickshell/ tmux/ qt6ct/ \
  --include='*.sh' --include='*.conf' --include='*.qml' --include='*.py'
```
Expected: no output. If any line still contains `jimdots` in a runtime file, it was missed — add a task to fix it.

- [ ] **Step 2: Confirm branding references are still intentionally present**

Run:
```bash
grep -rn 'jimdots' setup.sh scripts/lib.sh | head
```
Expected: only banner/log-filename branding text in `setup.sh` and `scripts/lib.sh` — these are deliberate, not paths.

- [ ] **Step 3: Syntax-check every modified bash file**

Run:
```bash
for f in hypr/*.sh; do bash -n "$f" && echo "ok: $f"; done
```
Expected: every file reports `ok:`.

- [ ] **Step 4: Smoke-test screenshot bind path**

Run:
```bash
ls -l ~/.config/hypr/screenshot.sh ~/.config/hypr/brightness-key.sh ~/.config/hypr/brightness-sync.sh ~/.config/hypr/gen-wallpaper.sh
```
Expected: all four resolve via the `~/.config/hypr` symlink and point back into the repo.

- [ ] **Step 5: Restart Quickshell and verify**

Run:
```bash
pkill -x quickshell; sleep 1; (uwsm app -- quickshell -c $HOME/.config/quickshell >/tmp/qs.log 2>&1 &)
```
Wait ~3 seconds, then:
```bash
tail -40 /tmp/qs.log
```
Expected: no path-related errors (no "file not found" / "No such file" referencing former `jimdots` paths). UI comes up normally.

- [ ] **Step 6: Toggle dark/light mode to exercise the sync paths**

Either via the quickshell settings UI or by flipping `darkMode` in `~/.config/quickshellsettings.toml`. Expected: wallpaper switches, kitty instances reload colors, btop/qt6ct/Kvantum/cursor/hypridle all update without error.

- [ ] **Step 7: Rename-test (optional but the point of the plan)**

If comfortable, rename the repo directory temporarily, re-run `./setup.sh --only symlinks`, log out, log back in:
```bash
mv ~/jimdots ~/test-soydots
cd ~/test-soydots
./setup.sh --only symlinks
# log out, log back in
```

Expected: everything still works. After verifying, rename back:
```bash
cd ~
mv ~/test-soydots ~/jimdots
cd ~/jimdots && ./setup.sh --only symlinks
```

Skip this step if you'd rather not reboot — the grep + quickshell smoke test covers the code paths.
