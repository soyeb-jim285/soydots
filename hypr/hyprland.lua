-- Hyprland config (Lua). See https://wiki.hypr.land/configuring/core/
-- Split files are loaded with require() at the bottom of this file.

------------
-- NVIDIA --
------------

-- hl.env("LIBVA_DRIVER_NAME", "nvidia")          -- disabled: GPU crash test
-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")  -- disabled: GPU crash test
-- hl.env("NVD_BACKEND", "direct")                -- disabled: GPU crash test

hl.config({
    cursor = {
        no_hardware_cursors = false,
    },
})


--------------
-- MONITORS --
--------------

hl.monitor({ output = "eDP-1",     mode = "preferred", position = "0x0",    scale = 1.6 })
hl.monitor({ output = "HDMI-A-1",  mode = "preferred", position = "1600x0", scale = 1, transform = 0 })


-----------------
-- MY PROGRAMS --
-----------------

local terminal    = "kitty"
local fileManager = "hyprfm"
local menu        = "hyprlauncher"


---------------
-- AUTOSTART --
---------------

hl.on("hyprland.start", function()
    hl.exec_cmd("uwsm finalize")
    hl.exec_cmd("hyprctl setcursor Dracula-cursors 24")
    hl.exec_cmd("uwsm app -- awww-daemon")
    hl.exec_cmd("uwsm app -- sh -c \"sleep 1 && ~/.config/hypr/gen-wallpaper.sh\"")
    hl.exec_cmd("uwsm app -- quickshell")
    hl.exec_cmd("uwsm app -- sh -c \"wl-paste --type text --watch cliphist store\"")
    hl.exec_cmd("uwsm app -- sh -c \"wl-paste --type image --watch cliphist store\"")
    hl.exec_cmd("uwsm app -- fcitx5 -d --replace")
end)


---------------------------
-- ENVIRONMENT VARIABLES --
---------------------------

hl.env("XCURSOR_THEME", "Dracula-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Dracula-cursors")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("SDL_IM_MODULE", "fcitx")
hl.env("GLFW_IM_MODULE", "ibus")
hl.env("TERMINAL", "kitty")


-----------------
-- PERMISSIONS --
-----------------

-- hl.config({ ecosystem = { enforce_permissions = true } })
-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


-------------------
-- LOOK AND FEEL --
-------------------

hl.config({
    general = {
        gaps_in  = 3,
        gaps_out = 8,

        border_size = 2,

        col = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        resize_on_border = true,
        allow_tearing    = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },

        blur = {
            enabled           = true,
            size              = 8,
            passes            = 3,
            new_optimizations = true,
            xray              = false,
            vibrancy          = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Caelestia-style animations (Material Design motion curves)
hl.curve("emphasizedDecel",   { type = "bezier", points = { {0.05, 0.7}, {0.1, 1}    } })
hl.curve("emphasizedAccel",   { type = "bezier", points = { {0.3,  0},   {0.8, 0.15} } })
hl.curve("standard",          { type = "bezier", points = { {0.2,  0},   {0,   1}    } })
hl.curve("specialWorkSwitch", { type = "bezier", points = { {0.05, 0.7}, {0.1, 1}    } })

-- Windows
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 5, bezier = "emphasizedDecel" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 3, bezier = "emphasizedAccel" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "fade",        enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "fadeDim",     enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "border",      enabled = true, speed = 6, bezier = "standard" })

-- Layers — use fade so centered layers (settings, launcher) don't slide from an edge
hl.animation({ leaf = "layersIn",   enabled = true, speed = 5, bezier = "emphasizedDecel", style = "fade" })
hl.animation({ leaf = "layersOut",  enabled = true, speed = 4, bezier = "emphasizedAccel", style = "fade" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 5, bezier = "standard" })

-- Workspaces
hl.animation({ leaf = "workspaces",       enabled = true, speed = 5, bezier = "standard" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "specialWorkSwitch", style = "slidefadevert 15%" })

-- "Smart gaps" / "No gaps when only" — uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({ name = "no-gaps-wtv1", match = { float = false, workspace = "w[tv1]" }, border_size = 0, rounding = 0 })
-- hl.window_rule({ name = "no-gaps-f1",   match = { float = false, workspace = "f[1]"   }, border_size = 0, rounding = 0 })

hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        focus_on_activate       = true,
    },
})


-----------
-- INPUT --
-----------

hl.config({
    input = {
        kb_layout = "us",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Example per-device config
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


-----------------
-- KEYBINDINGS --
-----------------

local mainMod = "SUPER"

hl.bind(mainMod .. " + Return",    hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q",         hl.dsp.window.close())
hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd("zen-browser"))
hl.bind(mainMod .. " + M",         hl.dsp.exec_cmd("quickshell msg powermenu toggle"))
hl.bind(mainMod .. " + L",         hl.dsp.exec_cmd("quickshell msg lockscreen lock"))
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.exec_cmd("~/.config/hypr/sleep-blockers.sh"))
hl.bind(mainMod .. " + E",         hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + ALT + V",   hl.dsp.window.float())
hl.bind(mainMod .. " + SPACE",     hl.dsp.exec_cmd("quickshell msg launcher toggle"))

-- Screenshots
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("~/.config/hypr/screenshot.sh region"))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("~/.config/hypr/screenshot.sh output"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("~/.config/hypr/screenshot.sh window"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.config/hypr/toggle-hdmi-rotate.sh"))

-- Clipboard / shell surfaces
hl.bind(mainMod .. " + V",         hl.dsp.exec_cmd("quickshell msg launcher openClipboard"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("quickshell msg animpicker toggle"))
hl.bind(mainMod .. " + comma",     hl.dsp.exec_cmd("quickshell msg settings toggle"))
hl.bind(mainMod .. " + U",         hl.dsp.exec_cmd("quickshell msg quill-showcase toggle"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("quickshell msg theme toggle"))

-- Keybinding cheatsheet (opens the launcher in keybindings search mode)
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("quickshell msg launcher openKeybinds"))

-- Wallpaper
hl.bind(mainMod .. " + ALT + W", hl.dsp.exec_cmd("~/.config/hypr/gen-wallpaper.sh"))

-- hl.bind(mainMod .. " + P", hl.dsp.window.pseudo()) -- dwindle
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left"  }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up"    }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down"  }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind(mainMod .. " + F6",     hl.dsp.exec_cmd("~/.config/hypr/brightness-key.sh set 5%+"),       { locked = true, repeating = true })
hl.bind(mainMod .. " + F5",     hl.dsp.exec_cmd("~/.config/hypr/brightness-key.sh set 5%-"),       { locked = true, repeating = true })

-- Lock key OSD
hl.bind("Caps_Lock", hl.dsp.exec_cmd("quickshell msg osd capslock"), { locked = true })
hl.bind("Num_Lock",  hl.dsp.exec_cmd("quickshell msg osd numlock"),  { locked = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


-----------------
-- LAYER RULES --
-----------------

-- Blur on all quickshell surfaces — ignore_alpha 0.3 (same as OSD which works)
-- Backdrop overlays use opacity 0.2 (below 0.3) so they don't trigger blur
-- Panel backgrounds use alpha ~0.85 (above 0.3) so blur shows through them
for _, ns in ipairs({
    "quickshell",
    "quickshell-osd",
    "quickshell-notif",
    "quickshell-launcher",
    "quickshell-clipboard",
    "quickshell-notifcenter",
    "quickshell-animpicker",
    "quickshell-settings",
    "quickshell-powermenu",
    "quill-showcase",
    "quickshell-polkit",
}) do
    hl.layer_rule({
        match        = { namespace = ns },
        blur         = true,
        ignore_alpha = 0.3,
    })
end


---------------------------
-- WINDOWS AND WORKSPACES --
---------------------------

-- Polkit agent styling
hl.window_rule({
    name  = "polkit-style",
    match = { class = "hyprpolkitagent" },

    float  = true,
    center = true,
})

hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = { "20", "monitor_h-120" },
    float = true,
})


-------------
-- MODULES --
-------------

-- Quickshell settings sync — auto-generated, loaded last to override defaults.
-- Machine-local overrides — gitignored, do not commit.
-- pcall: a missing module is a hard error that would kill this file.
pcall(require, "quickshell-theme")
pcall(require, "local")
