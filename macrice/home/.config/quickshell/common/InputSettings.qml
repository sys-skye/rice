pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Trackpad / mouse / keyboard settings for the System Settings window.
// Changes apply live (hyprctl keyword) and are saved to ~/.config/hypr/settings.conf,
// which hyprland.conf sources last so it overrides input.conf.
Singleton {
    id: root

    readonly property string confPath: Quickshell.env("HOME") + "/.config/hypr/settings.conf"
    readonly property string jsonPath: Quickshell.statePath("input-settings.json")

    // Trackpad
    property real sensitivity: 0          // -1 … 1
    property string accel: "adaptive"     // adaptive | flat
    property bool naturalScroll: true
    property bool tapToClick: true
    property bool tapAndDrag: true
    property bool twoFingerRightClick: true   // clickfinger_behavior
    property bool disableWhileTyping: true
    property real scrollFactor: 0.4
    property real terminalScroll: 1.5
    // Mouse (all external mice; per-device overrides below)
    property real mouseScrollFactor: 1.0
    property bool mouseNaturalScroll: false
    property var mice: ({})               // name → { sensitivity, accel }
    // Cursor ghost trail ("motion blur")
    property bool trailEnabled: true
    property real trailLength: 40         // px: longest the smear gets
    property real trailStrength: 0.55     // opacity of the nearest ghost
    property string trailType: "blur"     // blur (soft streak) | comet (glowing accent tail) | dots (separate bubbles)
    property string trailColor: "auto"    // "auto" (follows Light/Dark; accent for comet) or a "#rrggbb" colour
    // Three-finger swipe between Spaces
    property int swipeDistance: 300       // px of finger travel for one whole Space
    property real swipeSwitchAt: 0.5      // fraction of the swipe after which it switches
    property int swipeFlick: 30           // a flick faster than this switches anyway
    property bool swipeForever: false     // one long swipe can cross several Spaces
    // Tiled windows
    property int gapsIn: 4                // between windows (each side, so the gap looks twice this)
    property int gapsOut: 9               // to the screen edges
    property int rounding: 12             // window corner radius
    // Display (built-in screen): 2 = default, 1.333 = "More Space"
    property real displayScale: 2
    // External display (HDMI)
    readonly property string extName: "HDMI-A-1"
    property string extMode: ""            // "2560x1440@144"; "" = the monitor's preferred mode
    property real extScale: 1
    property string extPosition: "right"   // left | right | above | below (relative to the laptop)
    property bool extMirror: false         // show the same picture as the laptop
    property string mainDisplay: "builtin" // where the Dock lives: builtin | external
    property var extSize: [2560, 1440]     // current pixel size of the external screen (for placing it)
    // Keyboard
    property int repeatRate: 40
    property int repeatDelay: 250
    property string kbLayout: "us"         // xkb layouts, comma-separated ("us,de")
    property string capsLock: "compose"    // compose | escape | ctrl | none | caps

    property var connectedMice: []        // names of external mice right now
    property bool loaded: false

    // Built-in scales that give whole logical pixels (sharpest): 100%, 133%, 200%
    function exactScale(sc) { return [1, 1.333333, 2].some(x => Math.abs(x - sc) < 0.001) }
    // Same rule for the external screen at its current resolution
    function wholePixels(w, h, sc) { return Math.abs(w / sc - Math.round(w / sc)) < 0.01 && Math.abs(h / sc - Math.round(h / sc)) < 0.01 }
    function extPixels() { const m = /^(\d+)x(\d+)/.exec(extMode); return m ? [Number(m[1]), Number(m[2])] : extSize }
    function extExact() { const p = extPixels(); return wholePixels(p[0], p[1], extScale) }
    // In-between scales don't split the screen into whole pixels, so Hyprland's check has to be off for them
    function scaleChecksOff() { return !exactScale(displayScale) || !extExact() }
    function keyword(k, v) { Quickshell.execDetached(["hyprctl", "keyword", k, String(v)]) }
    function b(v) { return v ? 1 : 0 }
    // xkb options for the Caps Lock choice (+ ⌃Space switches layouts when there are several)
    function kbOptions() {
        const caps = { compose: "compose:caps", escape: "caps:escape", ctrl: "ctrl:nocaps", none: "caps:none", caps: "caps:capslock" }[capsLock] ?? ""
        return [caps, kbLayout.indexOf(",") >= 0 ? "grp:ctrl_space_toggle" : ""].filter(x => x).join(",")
    }

    function set(prop, value) {
        root[prop] = value
        switch (prop) {
        case "sensitivity": keyword("input:sensitivity", value.toFixed(2)); break
        case "accel": keyword("input:accel_profile", value); break
        case "naturalScroll": keyword("input:touchpad:natural_scroll", b(value)); break
        case "tapToClick": keyword("input:touchpad:tap-to-click", b(value)); break
        case "tapAndDrag": keyword("input:touchpad:tap-and-drag", b(value)); break
        case "twoFingerRightClick": keyword("input:touchpad:clickfinger_behavior", b(value)); break
        case "disableWhileTyping": keyword("input:touchpad:disable_while_typing", b(value)); break
        case "scrollFactor": keyword("input:touchpad:scroll_factor", value.toFixed(2)); break
        case "mouseScrollFactor": keyword("input:scroll_factor", value.toFixed(2)); break
        case "mouseNaturalScroll": keyword("input:natural_scroll", b(value)); break
        case "repeatRate": keyword("input:repeat_rate", value); break
        case "repeatDelay": keyword("input:repeat_delay", value); break
        case "kbLayout": case "capsLock":
            Quickshell.execDetached(["hyprctl", "--batch", "keyword input:kb_layout " + kbLayout + "; keyword input:kb_options " + kbOptions()])
            break
        case "swipeDistance": keyword("gestures:workspace_swipe_distance", value); break
        case "swipeSwitchAt": keyword("gestures:workspace_swipe_cancel_ratio", value.toFixed(2)); break
        case "swipeFlick": keyword("gestures:workspace_swipe_min_speed_to_force", value); break
        case "swipeForever": keyword("gestures:workspace_swipe_forever", b(value)); break
        case "gapsIn": keyword("general:gaps_in", value); break
        case "gapsOut": keyword("general:gaps_out", value); break
        case "rounding": keyword("decoration:rounding", value); break
        case "displayScale":
            Quickshell.execDetached(["hyprctl", "--batch", "keyword debug:disable_scale_checks " + b(scaleChecksOff())
                                     + "; keyword monitor eDP-1,preferred,auto," + value.toFixed(6)
                                     + "; keyword monitor " + extMonitorLine()])
            break
        case "extMode": case "extScale": case "extPosition": case "extMirror": applyExternal(); break
        }
        saveTimer.restart()
    }
    function setMouse(name, key, value) {
        const m = Object.assign({}, mice)
        m[name] = Object.assign({ sensitivity: 0, accel: "adaptive" }, m[name] || {})
        m[name][key] = value
        mice = m
        keyword("device[" + name + "]:" + (key === "accel" ? "accel_profile" : "sensitivity"),
                key === "accel" ? value : Number(value).toFixed(2))
        saveTimer.restart()
    }
    function mouse(name) { return Object.assign({ sensitivity: 0, accel: "adaptive" }, mice[name] || {}) }

    // Where the external screen goes, in Hyprland's layout coordinates
    function extPositionString() {
        const lw = Math.round(3024 / displayScale), lh = Math.round(1964 / displayScale)
        const m = /^(\d+)x(\d+)/.exec(extMode)
        const ew = Math.round((m ? Number(m[1]) : extSize[0]) / extScale)
        const eh = Math.round((m ? Number(m[2]) : extSize[1]) / extScale)
        switch (extPosition) {
        case "left": return (-ew) + "x0"
        case "above": return Math.round((lw - ew) / 2) + "x" + (-eh)
        case "below": return Math.round((lw - ew) / 2) + "x" + lh
        }
        return lw + "x0"
    }
    function extMonitorLine() {
        return extName + "," + (extMode || "preferred") + "," + extPositionString() + "," + extScale.toFixed(6)
             + (extMirror ? ",mirror,eDP-1" : "")
    }
    function applyExternal() {
        Quickshell.execDetached(["hyprctl", "--batch", "keyword debug:disable_scale_checks " + b(scaleChecksOff())
                                 + "; keyword monitor " + extMonitorLine()])
    }

    function confText() {
        let t = "# Written by System Settings (Apple menu). Edits here get overwritten —\n"
              + "# change things in the app, or put permanent tweaks in input.conf instead.\n\n"
              + "input:sensitivity = " + sensitivity.toFixed(2) + "\n"
              + "input:accel_profile = " + accel + "\n"
              + "input:scroll_factor = " + mouseScrollFactor.toFixed(2) + "\n"
              + "input:natural_scroll = " + mouseNaturalScroll + "\n"
              + "input:repeat_rate = " + repeatRate + "\n"
              + "input:repeat_delay = " + repeatDelay + "\n"
              + "input:kb_layout = " + kbLayout + "\n"
              + "input:kb_options = " + kbOptions() + "\n"
              + "input:touchpad:natural_scroll = " + naturalScroll + "\n"
              + "input:touchpad:tap-to-click = " + tapToClick + "\n"
              + "input:touchpad:tap-and-drag = " + tapAndDrag + "\n"
              + "input:touchpad:clickfinger_behavior = " + twoFingerRightClick + "\n"
              + "input:touchpad:disable_while_typing = " + disableWhileTyping + "\n"
              + "input:touchpad:scroll_factor = " + scrollFactor.toFixed(2) + "\n\n"
              + "# Tiled windows\n"
              + "general:gaps_in = " + gapsIn + "\n"
              + "general:gaps_out = " + gapsOut + "\n"
              + "decoration:rounding = " + rounding + "\n\n"
              + "# Three-finger swipe between Spaces\n"
              + "gestures:workspace_swipe_distance = " + swipeDistance + "\n"
              + "gestures:workspace_swipe_cancel_ratio = " + swipeSwitchAt.toFixed(2) + "\n"
              + "gestures:workspace_swipe_min_speed_to_force = " + swipeFlick + "\n"
              + "gestures:workspace_swipe_forever = " + swipeForever + "\n\n"
              + (scaleChecksOff() ? "# Allow in-between display scales\ndebug:disable_scale_checks = 1\n\n" : "")
              + (Math.abs(displayScale - 2) > 0.01 ? "# Built-in display scale\n"
                 + "monitor = eDP-1, preferred, auto, " + displayScale.toFixed(6) + "\n\n" : "")
              + "# External display (HDMI): mode, position, scale\nmonitor = " + extMonitorLine().replace(/,/g, ", ") + "\n\n"
              + "# Terminal scrolling speed on the trackpad\n"
              + "windowrule = match:class ^(kitty|Alacritty|foot|floating-term)$, scroll_touchpad " + terminalScroll.toFixed(2) + "\n"
        for (const name of Object.keys(mice)) {
            const m = mouse(name)
            t += "\ndevice {\n    name = " + name + "\n    sensitivity = " + Number(m.sensitivity).toFixed(2)
               + "\n    accel_profile = " + m.accel + "\n}\n"
        }
        return t
    }
    function save() {
        const json = JSON.stringify({
            sensitivity, accel, naturalScroll, tapToClick, tapAndDrag, twoFingerRightClick, disableWhileTyping,
            scrollFactor, terminalScroll, mouseScrollFactor, mouseNaturalScroll, mice, repeatRate, repeatDelay, kbLayout, capsLock,
            trailEnabled, trailLength, trailStrength, trailType, trailColor, displayScale,
            swipeDistance, swipeSwitchAt, swipeFlick, swipeForever, gapsIn, gapsOut, rounding,
            extMode, extScale, extPosition, extMirror, mainDisplay
        }, null, 2)
        writer.command = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s\\n' \"$2\" > \"$1\" && printf '%s' \"$3\" > \"$4\" && hyprctl reload >/dev/null",
                          "sh", jsonPath, json, confText(), confPath]
        writer.running = true
    }
    Timer { id: saveTimer; interval: 600; onTriggered: root.save() }
    Process { id: writer }

    // Load saved values; first run starts from what Hyprland is using now
    Process {
        running: true
        command: ["sh", "-c", "cat '" + root.jsonPath + "' 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let saved = {}
                try { saved = JSON.parse(text) } catch (e) {}
                for (const k of Object.keys(saved)) if (k in root) root[k] = saved[k]
                root.loaded = true
                if (Object.keys(saved).length === 0) current.running = true
            }
        }
    }
    Process {
        id: current
        command: ["sh", "-c", "for o in input:sensitivity input:touchpad:scroll_factor input:repeat_rate input:repeat_delay; do hyprctl getoption $o -j; done | jq -s -c 'map(.float // .int)'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const v = JSON.parse(text)
                    root.sensitivity = v[0]; root.scrollFactor = v[1]; root.repeatRate = v[2]; root.repeatDelay = v[3]
                } catch (e) {}
            }
        }
    }

    // Which external mice are plugged in (refreshed while Settings is open)
    function refreshMice() { miceProc.running = true }
    Process {
        id: miceProc
        command: ["sh", "-c", "hyprctl devices -j | jq -c '[.mice[].name | select(test(\"mtp|touchpad|trackpad|ydotool|virtual\") | not)]'"]
        stdout: StdioCollector { onStreamFinished: { try { root.connectedMice = JSON.parse(text) } catch (e) {} } }
    }
}
