-- Keyboard shortcuts. Super = ⌘. Press Super + / to search all of these.
-- bind(KEYS, Description, dispatcher or function[, options])
-- (The ⌘/ cheat sheet reads this file: keep each bind(...) starting on one line,
--  and the "-- ── Section ──" comments become its headings.)

local scripts = "~/.config/hypr/scripts"
local terminal = "kitty"
local files = "nautilus --new-window"
local browser = "firefox"

local dsp = hl.dsp

local function bind(keys, desc, action, opts)
    opts = opts or {}
    if desc ~= "" then opts.description = desc end
    hl.bind(keys, action, opts)
end
local function exec(cmd) return dsp.exec_cmd(cmd) end
local function script(cmd) return dsp.exec_cmd(scripts .. "/" .. cmd) end
-- ⌘+key is sent to the app as Ctrl+key
local function send(mods, key) return dsp.send_shortcut({ mods = mods, key = key }) end
-- Run several dispatchers on one key
local function all(...)
    local list = { ... }
    return function()
        for _, d in ipairs(list) do hl.dispatch(d) end
    end
end

-- ── Apps ────────────────────────────────────────────────────────────
bind("SUPER + SPACE", "Search apps (⌘↩ opens on a new Space)", script("launcher"))
bind("SUPER + RETURN", "Terminal", exec("uwsm-app -- " .. terminal))
bind("SUPER + GRAVE", "Drop-down terminal", script("dropdown-term"))
bind("SUPER + E", "Files (Finder)", exec("uwsm-app -- " .. files))
bind("SUPER + B", "Browser", exec("uwsm-app -- " .. browser))
bind("SUPER + ESCAPE", "System menu", exec("qs ipc call panel toggle system"))
bind("SUPER + ALT + SPACE", "Control Center", exec("qs ipc call panel toggle control"))
bind("SUPER + SLASH", "Keyboard shortcuts", exec("qs ipc call panel toggle keybinds"))
bind("SUPER + SHIFT + V", "Clipboard history", script("clipboard"))
bind("SUPER + SHIFT + C", "Color picker", exec("hyprpicker -a -n"))
bind("SUPER + CTRL + Q", "Lock screen", exec("loginctl lock-session"))
bind("SUPER + SHIFT + B", "Restart menu bar and dock", script("bars restart"))

-- ── Editing (⌘+key is sent to the app as Ctrl+key) ────────────────
-- So ⌘C / ⌘V / ⌘T etc. work like on a Mac in browsers, editors, and terminals.
bind("SUPER + C", "Copy", send("CTRL", "Insert"))
bind("SUPER + V", "Paste", send("SHIFT", "Insert"))
bind("SUPER + X", "Cut", send("CTRL", "X"))
bind("SUPER + A", "Select all", send("CTRL", "A"))
bind("SUPER + Z", "Undo", send("CTRL", "Z"))
bind("SUPER + SHIFT + Z", "Redo", send("CTRL SHIFT", "Z"))
bind("SUPER + S", "Save", send("CTRL", "S"))
bind("SUPER + F", "Find", send("CTRL", "F"))
bind("SUPER + T", "New tab", send("CTRL", "T"))
bind("SUPER + SHIFT + T", "Reopen closed tab", send("CTRL SHIFT", "T"))
bind("SUPER + W", "Close tab", script("cmd-w"))
bind("SUPER + N", "New window", send("CTRL", "N"))
bind("SUPER + R", "Reload", send("CTRL", "R"))
bind("SUPER + L", "Address bar", send("CTRL", "L"))
bind("SUPER + P", "Print", send("CTRL", "P"))

-- ── Windows ─────────────────────────────────────────────────────────
bind("SUPER + Q", "Quit app (some keep running hidden)", script("cmd-q"))
bind("SUPER + M", "Minimize / restore window", script("minimize"))
bind("SUPER + SHIFT + M", "Show minimized windows", function()
    -- tells scripts/hidden-apps this overlay was opened on purpose
    local peek = io.open(os.getenv("XDG_RUNTIME_DIR") .. "/minimized-peek", "w")
    if peek then peek:close() end
    hl.dispatch(dsp.workspace.toggle_special("minimized"))
end)
bind("SUPER + CTRL + F", "Fullscreen", dsp.window.fullscreen({ mode = "fullscreen" }))
bind("SUPER + ALT + F", "Float / tile window", all(dsp.window.float({ action = "toggle" }), dsp.window.center()))
bind("SUPER + ALT + J", "Flip split direction", dsp.layout("togglesplit"))
bind("SUPER + CTRL + UP", "Show all windows (Mission Control)", exec("qs ipc call overview toggle"))
bind("SUPER + TAB", "Next window", all(dsp.window.cycle_next(), dsp.window.alter_zorder({ mode = "top" })))
bind("SUPER + SHIFT + TAB", "Previous window", all(dsp.window.cycle_next({ next = false }), dsp.window.alter_zorder({ mode = "top" })))

bind("SUPER + LEFT", "Focus left", dsp.focus({ direction = "left" }))
bind("SUPER + RIGHT", "Focus right", dsp.focus({ direction = "right" }))
bind("SUPER + UP", "Focus up", dsp.focus({ direction = "up" }))
bind("SUPER + DOWN", "Focus down", dsp.focus({ direction = "down" }))
bind("SUPER + SHIFT + LEFT", "Move window left", dsp.window.swap({ direction = "left" }))
bind("SUPER + SHIFT + RIGHT", "Move window right", dsp.window.swap({ direction = "right" }))
bind("SUPER + SHIFT + UP", "Move window up", dsp.window.swap({ direction = "up" }))
bind("SUPER + SHIFT + DOWN", "Move window down", dsp.window.swap({ direction = "down" }))
bind("SUPER + ALT + LEFT", "Shrink width", dsp.window.resize({ x = -60, y = 0, relative = true }), { repeating = true })
bind("SUPER + ALT + RIGHT", "Grow width", dsp.window.resize({ x = 60, y = 0, relative = true }), { repeating = true })
bind("SUPER + ALT + UP", "Shrink height", dsp.window.resize({ x = 0, y = -60, relative = true }), { repeating = true })
bind("SUPER + ALT + DOWN", "Grow height", dsp.window.resize({ x = 0, y = 60, relative = true }), { repeating = true })

-- Super + drag to move, Super + right-drag to resize
bind("SUPER + mouse:272", "Move window", dsp.window.drag(), { mouse = true })
bind("SUPER + mouse:273", "Resize window", dsp.window.resize(), { mouse = true })

-- ── Spaces (workspaces) ─────────────────────────────────────────────
-- Also: three-finger swipe left/right on the trackpad
-- Each display has its own Spaces 1, 2, 3… (scripts/space); these act on the focused display
bind("SUPER + CTRL + LEFT", "Previous space", script("space prev"))
bind("SUPER + CTRL + RIGHT", "Next space", script("space next"))
bind("SUPER + ALT + Page_Up", "Previous space on every display", script("space prev-all"))
bind("SUPER + ALT + Page_Down", "Next space on every display", script("space next-all"))
bind("SUPER + CTRL + SHIFT + LEFT", "Move window to previous space", script("space moveprev"))
bind("SUPER + CTRL + SHIFT + RIGHT", "Move window to next space", script("space movenext"))
bind("SUPER + CTRL + ALT + LEFT", "Move window to the display on the left", dsp.window.move({ monitor = "l" }))
bind("SUPER + CTRL + ALT + RIGHT", "Move window to the display on the right", dsp.window.move({ monitor = "r" }))
bind("SUPER + CTRL + ALT + SHIFT + LEFT", "Move this space to the display on the left", dsp.workspace.move({ monitor = "l" }))
bind("SUPER + CTRL + ALT + SHIFT + RIGHT", "Move this space to the display on the right", dsp.workspace.move({ monitor = "r" }))
bind("SUPER + mouse_down", "Next space", dsp.focus({ workspace = "m+1" }))
bind("SUPER + mouse_up", "Previous space", dsp.focus({ workspace = "m-1" }))

-- ⌘N = Space N of the display you're on (never pulls or swaps one from the other screen)
-- (code:10…18 are the 1…9 keys, whatever the keyboard layout)
bind("SUPER + code:10", "Space 1", script("space go 1"))
bind("SUPER + code:11", "Space 2", script("space go 2"))
bind("SUPER + code:12", "Space 3", script("space go 3"))
bind("SUPER + code:13", "Space 4", script("space go 4"))
bind("SUPER + code:14", "Space 5", script("space go 5"))
bind("SUPER + code:15", "Space 6", script("space go 6"))
bind("SUPER + code:16", "Space 7", script("space go 7"))
bind("SUPER + code:17", "Space 8", script("space go 8"))
bind("SUPER + code:18", "Space 9", script("space go 9"))
bind("SUPER + ALT + code:10", "Move window to space 1", script("space move 1"))
bind("SUPER + ALT + code:11", "Move window to space 2", script("space move 2"))
bind("SUPER + ALT + code:12", "Move window to space 3", script("space move 3"))
bind("SUPER + ALT + code:13", "Move window to space 4", script("space move 4"))
bind("SUPER + ALT + code:14", "Move window to space 5", script("space move 5"))
bind("SUPER + ALT + code:15", "Move window to space 6", script("space move 6"))
bind("SUPER + ALT + code:16", "Move window to space 7", script("space move 7"))
bind("SUPER + ALT + code:17", "Move window to space 8", script("space move 8"))
bind("SUPER + ALT + code:18", "Move window to space 9", script("space move 9"))
bind("SUPER + ALT + code:19", "Move window to a new empty space", script("space move new"))

-- ── Screenshots (saved to ~/Pictures/Screenshots + copied) ──────────
bind("SUPER + SHIFT + code:12", "Screenshot whole screen", script("screenshot screen"))
bind("SUPER + SHIFT + code:13", "Screenshot selection", script("screenshot region"))
bind("SUPER + SHIFT + code:14", "Screenshot selection and annotate", script("screenshot edit"))
bind("PRINT", "Screenshot selection", script("screenshot region"))

-- ── Hardware keys ───────────────────────────────────────────────────
local held = { repeating = true, locked = true } -- keeps going while held, works on the lock screen
local locked = { locked = true }
bind("XF86AudioRaiseVolume", "Volume up", script("osd volume +5"), held)
bind("XF86AudioLowerVolume", "Volume down", script("osd volume -5"), held)
bind("XF86AudioMute", "Mute", script("osd volume mute"), held)
bind("XF86AudioMicMute", "Mute microphone", script("osd mic mute"), held)
bind("XF86MonBrightnessUp", "Brightness up", script("osd brightness +5%"), held)
bind("XF86MonBrightnessDown", "Brightness down", script("osd brightness 5%-"), held)
bind("XF86KbdBrightnessUp", "Keyboard light up", script("osd keyboard +10%"), held)
bind("XF86KbdBrightnessDown", "Keyboard light down", script("osd keyboard 10%-"), held)
bind("XF86AudioPlay", "Play / pause", exec("playerctl play-pause"), locked)
bind("XF86AudioPause", "Play / pause", exec("playerctl play-pause"), locked)
bind("XF86AudioNext", "Next track", exec("playerctl next"), locked)
bind("XF86AudioPrev", "Previous track", exec("playerctl previous"), locked)

-- ── While app search is open ────────────────────────────────────────
-- Keys go to fuzzel (so ⌘↩ = open on a new Space, not a terminal)
hl.define_submap("launcher", function()
    bind("SUPER + SPACE", "Close search", exec("pkill -x fuzzel"))
end)
