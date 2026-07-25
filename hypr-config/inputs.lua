-- Input configuration
-- Based on CachyOS/cachyos-hypr-noctalia's default etc/skel/.config/hypr/config/inputs.lua
-- (this whole config/*.lua + hyprland.lua structure is CachyOS's own, deployed via
-- /etc/skel when noctalia-shell was installed — Hyprland 0.55+ prefers hyprland.lua
-- over hyprland.conf entirely if it exists, which is why the old flat hyprland.conf
-- in this repo was silently never read no matter how it was edited).

hl.config({
    input = {
        -- sensitivity = -0.25,
        accel_profile = "flat",
        -- fr (AZERTY) listed first so it's the active layout on login, matching the
        -- physical keyboard — "us" loading by default was the original complaint.
        kb_layout = "fr,us,kr",
        -- Alt+Shift cycles fr -> us -> kr. Deliberately not SUPER+Space — that's
        -- Vicinae's toggle bind (see binds.lua), same combo can't do both.
        kb_options = "grp:alt_shift_toggle",
        numlock_by_default = true,
        touchpad = {
            -- Hyprland's compiled-in default here is false, which read backwards —
            -- flipped to true.
            natural_scroll = true,
        },
    },
    -- Uncomment the section below to enable software cursors; this can help with cursor display or behavior issues
    -- cursor = {
    --     no_hardware_cursors = 1,
    -- },
})

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "down",       action = "close" })
hl.gesture({ fingers = 3, direction = "up",         action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "left",       action = "float" })
