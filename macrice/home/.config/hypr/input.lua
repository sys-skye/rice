-- Control your input devices
-- Values changed in System Settings (Apple menu) are saved to settings.lua and override these.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
hl.config({
    input = {
        -- Use multiple keyboard layouts and switch between them with Left Alt + Right Alt
        -- kb_layout = "us,dk,eu",
        kb_options = "compose:caps", -- ,grp:alts_toggle

        -- Change speed of keyboard repeat
        repeat_rate = 40,
        repeat_delay = 250,

        touchpad = {
            -- Natural (inverse) scrolling, like macOS
            natural_scroll = true,
            -- Use two-finger clicks for right-click instead of lower-right corner
            clickfinger_behavior = true,
            -- Control the speed of your scrolling
            scroll_factor = 0.4,
            -- Tap to click
            tap_to_click = true,
        },
    },
})

-- Terminal scroll speed: set in System Settings → Trackpad & Mouse (settings.lua)

-- Three-finger swipe to change workspaces
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Three-finger swipe up: see all open windows (Mission Control).
-- Swipe down: go to the window under the pointer (or just close it)
hl.gesture({ fingers = 3, direction = "up", action = function() hl.dispatch(hl.dsp.exec_cmd("qs ipc call overview toggle")) end })
hl.gesture({ fingers = 3, direction = "down", action = function() hl.dispatch(hl.dsp.exec_cmd("qs ipc call overview commit")) end })
