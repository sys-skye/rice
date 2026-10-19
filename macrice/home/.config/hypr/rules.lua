-- Window rules: https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Apps that make more sense as floating panels than tiles
hl.window_rule({
    match = { class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-connection-editor|org.gnome.Calculator|nwg-look|com.gabm.satty|imv|mpv|org.gnome.Loupe|xdg-desktop-portal-gtk|org.gnome.NautilusPreviewer)$" },
    float = true,
})
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-connection-editor|nwg-look)$" }, size = "900 600" })
hl.window_rule({ match = { float = true }, center = true })
hl.window_rule({ match = { title = "^(Open.*|Save.*|Choose.*|.*wants to (open|save).*)$" }, float = true })
hl.window_rule({ match = { class = "^(floating-term)$" }, float = true, size = "900 560" })

-- System Settings (Apple menu): floating, centred, like the macOS app
hl.window_rule({ match = { class = "^(org.quickshell)$", title = "^(System Settings)$" }, float = true, size = "860 600", center = true })

-- About This Computer (Apple menu): small fixed card
hl.window_rule({ match = { class = "^(about-this-computer)$" }, float = true, size = "990 560", center = true })

-- Picture-in-picture: small, pinned to every workspace, top-right corner
hl.window_rule({
    match = { title = "^(Picture.?in.?[Pp]icture)$" },
    float = true,
    pin = true,
    size = "600 338",
    move = "(monitor_w-window_w-24) 56",
})

-- Don't let apps maximize themselves out of the tiling layout
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

-- Fix XWayland drag-and-drop ghosts
hl.window_rule({
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Frosted glass behind the menu bar, dock, Spotlight and notifications
hl.layer_rule({ match = { namespace = "^(menubar|dock|dropdown|launcher|notifications|overview)$" }, blur = true })
hl.layer_rule({ match = { namespace = "^(menubar|dock)$" }, blur_popups = true })
hl.layer_rule({ match = { namespace = "^(menubar|dock|dropdown|launcher|notifications)$" }, ignore_alpha = 0.2 })
hl.layer_rule({ match = { namespace = "^(launcher)$" }, animation = "popin 92%" })
hl.layer_rule({ match = { namespace = "^(selection|hyprpicker|backdrop|dropdown|cheatsheet|cursortrail|overview|notchmorph|notchosd)$" }, no_anim = true })

-- JetBrains IDEs (IntelliJ…): don't let the mouse move focus onto completion
-- popups/tooltips, which would close them while you type
hl.window_rule({ name = "jetbrains-focus", match = { class = "^(jetbrains-.*)$" }, no_follow_mouse = true })
-- …and float their welcome/first-run/licence windows like the Mac versions do
hl.window_rule({
    match = {
        class = "^(jetbrains-.*)$",
        title = "^(Welcome to .*|.*User Agreement|.*Data Sharing.*|Licen[cs]es?|Manage Licenses.*|Import .*Settings.*|Tip of the Day)$",
    },
    float = true,
    center = true,
})

-- Drop-down terminal (⌘`): a kitty window in the hidden "dropdown" Space,
-- half the screen wide, centred just under the menu bar (rounded like every window)
hl.window_rule({
    match = { class = "^(dropdown-term)$" },
    workspace = "special:dropdown silent",
    float = true,
    size = "(monitor_w*0.5) (monitor_h*0.48)",
    move = "(monitor_w*0.25) 38",
})
