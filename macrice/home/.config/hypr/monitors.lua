-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and resolutions possible: hyprctl monitors

-- MacBook Pro 14" (3024x1964 with the notch area shown). Scale 2 = 1512x982 logical.
-- 1.75 is not a valid scale for this panel (Hyprland silently falls back to 2).
hl.env("GDK_SCALE", "2")
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 2 })

-- Any external monitor: pick a sensible default
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Each display owns a block of Space ids, so its Spaces are numbered 1, 2, 3…
-- independently (scripts/space, scripts/compact-spaces): the MacBook has 1–99,
-- the HDMI screen 101–199. Pinning them here makes Spaces created any way
-- (keys, swipes, session restore) open on the right screen.
-- (Hyprland only honours exact ids for this, not r[a-b] ranges.)
local blocks = { ["eDP-1"] = 0, ["HDMI-A-1"] = 100 }
for output, base in pairs(blocks) do
    for id = base + 1, base + 99 do
        hl.workspace_rule({ workspace = tostring(id), monitor = output })
    end
end
