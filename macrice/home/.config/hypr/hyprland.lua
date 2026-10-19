-- ┌──────────────────────────────────────────────────────────┐
-- │  macOS-style Hyprland rice                               │
-- │  Super (⌘) is the main modifier. Super + / lists keys.   │
-- │  Installed with macrice (see ~/macrice/README.md)       │
-- └──────────────────────────────────────────────────────────┘
-- Wiki: https://wiki.hypr.land/Configuring/
-- Lua config (Hyprland 0.55+). The old hyprland.conf files are only a fallback:
-- Hyprland uses this file whenever it exists.
--
-- Scripts talk to Hyprland in Lua too:
--   hyprctl dispatch 'hl.dsp.focus({ workspace = 3 })'
--   hyprctl eval 'hl.config({ general = { gaps_in = 4 } })'   (instead of `keyword`)

-- Optional files written by the apps (may not exist yet)
local dir = debug.getinfo(1, "S").source:match("^@(.*/)") or (os.getenv("HOME") .. "/.config/hypr/")
local function optional(name)
    local f = io.open(dir .. name .. ".lua", "r")
    if f then
        f:close()
        require(name)
    end
end

require("monitors")    -- display + scaling
require("envs")        -- environment variables
optional("cursor")     -- cursor theme + size (written by scripts/cursor-apply)
require("input")       -- keyboard, trackpad, gestures
require("looknfeel")   -- gaps, rounding, blur, animations
require("rules")       -- window + layer rules
require("bindings")    -- keyboard shortcuts
require("autostart")   -- bar, dock, wallpaper, daemons
optional("settings")   -- written by System Settings (overrides the above)
optional("appearance") -- written by the Light/Dark switch
