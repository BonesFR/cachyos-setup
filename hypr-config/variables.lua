-- Based on CachyOS/cachyos-hypr-noctalia's default etc/skel/.config/hypr/config/variables.lua.
-- TERMINAL must always have a value — binds.lua concatenates it directly
-- (launchPrefix .. TERMINAL) on the very first launcher bind, so an undefined
-- TERMINAL throws a Lua error there and silently kills every bind declared
-- after it in that file, including SUPER+Space and SUPER+T.

-- Hyprland default apps

TERMINAL     = "kitty"
FILE_MANAGER = "dolphin"
BROWSER      = "firefox"
EDITOR       = "gnome-text-editor --new-window"
CALCULATOR   = "gnome-calculator"

-- Monitors
MONITOR1 = ""
MONITOR2 = ""
MONITOR3 = ""
PRIMARY_MONITOR = MONITOR1

-- Workspaces
NUM_WPM = 3 -- Number of workspaces per monitor (Max 10)
