-- Cursor theme/size: see cursor.lua (set from System Settings or GTK Settings)

-- KDE/Qt apps (Dolphin, KWrite…) use KDE's colours, icons and style, so they follow Light/Dark
hl.env("QT_QPA_PLATFORMTHEME", "kde")

-- Prefer Wayland everywhere
hl.env("GDK_BACKEND", "wayland,x11,*")
-- Plain "wayland" (not "wayland;xcb"): with the fallback list, `qs ipc` can't find the
-- running Quickshell, so every Quickshell shortcut/gesture silently does nothing.
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

hl.config({
    -- Let X11 apps render at native resolution instead of blurry upscaling
    xwayland = { force_zero_scaling = true },
    ecosystem = { no_update_news = true, no_donation_nag = true },
})
