-- macOS-ish look: soft rounded corners, big diffuse shadows, frosted blur

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 9,
        border_size = 1,
        col = {
            active_border = "rgba(ffffff30)",
            inactive_border = "rgba(ffffff12)",
        },
        resize_on_border = true, -- drag window edges to resize, like macOS
        layout = "dwindle",
    },

    decoration = {
        rounding = 12,
        rounding_power = 3, -- squircle-like corners

        active_opacity = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled = true,
            range = 30,
            render_power = 4,
            offset = "0 8",
            color = "rgba(00000070)",
            color_inactive = "rgba(00000040)",
        },

        blur = {
            enabled = true,
            size = 8,
            passes = 3,
            noise = 0.02,
            vibrancy = 0.25,
            popups = true,
        },
    },

    animations = { enabled = true },

    dwindle = { preserve_split = true },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        focus_on_activate = true,
        key_press_enables_dpms = true,
        mouse_move_enables_dpms = true,
        background_color = "rgb(111122)",
    },

    cursor = { hide_on_key_press = true },

    binds = { hide_special_on_workspace_change = true },
})

hl.curve("macOut", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("macIn", { type = "bezier", points = { { 0.7, 0 }, { 0.84, 0 } } })
hl.curve("smooth", { type = "bezier", points = { { 0.25, 0.1 }, { 0.25, 1 } } })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "macOut", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "macIn", style = "popin 90%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "macOut" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "smooth" })
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "smooth" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3, bezier = "macOut", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2, bezier = "macIn", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "macOut", style = "slide" })      -- Spaces-style sliding
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "smooth", style = "fade" }) -- hidden Spaces (minimized, drop-down terminal)
