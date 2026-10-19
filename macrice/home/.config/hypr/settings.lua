-- Written by System Settings (Apple menu). Edits here get overwritten —
-- change things in the app, or put permanent tweaks in input.lua instead.

hl.config({
    input = { sensitivity = 0.12, accel_profile = "adaptive", scroll_factor = 1, natural_scroll = false, repeat_rate = 40, repeat_delay = 250, kb_layout = "us", kb_options = "compose:caps", touchpad = { natural_scroll = true, tap_to_click = true, tap_and_drag = true, clickfinger_behavior = true, disable_while_typing = true, scroll_factor = 0.67 } },
    -- Tiled windows
    general = { gaps_in = 2, gaps_out = 4 },
    decoration = { rounding = 14 },
    -- Three-finger swipe between Spaces
    gestures = { workspace_swipe_distance = 275, workspace_swipe_cancel_ratio = 0.15, workspace_swipe_min_speed_to_force = 10, workspace_swipe_forever = false },
    -- Allow in-between display scales
    debug = { disable_scale_checks = true },
})

-- Built-in display scale
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.85 })

-- External display (HDMI): mode, position, scale
hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@120.00", position = "-1829x0", scale = 1.4 })

-- Terminal scrolling speed on the trackpad
hl.window_rule({ name = "terminal-scroll", match = { class = "^(kitty|Alacritty|foot|floating-term)$" }, scroll_touchpad = 1.5 })
