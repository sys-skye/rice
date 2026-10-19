pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The rest of System Settings: menu bar clock, accent colour, notifications,
// lock screen (writes hypridle.conf) and Night Shift. State: prefs.json.
Singleton {
    id: root

    readonly property string jsonPath: Quickshell.statePath("prefs.json")
    readonly property string home: Quickshell.env("HOME")

    // Menu bar clock
    property bool clock24h: true
    property bool clockSeconds: false
    property bool clockDate: true
    readonly property string clockFormat: (clockDate ? "ddd d MMM   " : "")
        + (clock24h ? "HH:mm" : "h:mm") + (clockSeconds ? ":ss" : "") + (clock24h ? "" : " AP")
    // Accent colour (buttons, selections, sliders…)
    property string accent: "#0a84ff"
    // Notifications (mako)
    property int bannerSeconds: 5
    property string bannerPosition: "top-right"     // top-right | top-center
    // Lock screen (hypridle). Minutes; 0 = never
    property int displayOffAfter: 5
    property int lockDelay: 0                       // minutes after the display turns off; -1 = never
    // Night Shift (hyprsunset)
    property int nightTemp: 4500
    property bool nightSchedule: false
    property int nightFrom: 21
    property int nightTo: 7

    property bool loaded: false

    function set(prop, value) {
        root[prop] = value
        if (prop === "bannerSeconds" || prop === "bannerPosition") writeMako()
        if (prop === "displayOffAfter" || prop === "lockDelay") writeIdle()
        if (prop === "nightTemp" && Ui.nightLight) Ui.setNightLight(true)
        if (prop.startsWith("night") && prop !== "nightTemp") checkSchedule(true)
        saveTimer.restart()
    }

    function sh(script, ...args) { Quickshell.execDetached(["sh", "-c", script, "sh", ...args]) }

    function writeMako() {
        sh("printf '%s' \"$2\" > \"$1\" && makoctl reload", home + "/.config/mako/settings",
           "# Written by System Settings → Notifications\n"
           + "default-timeout=" + bannerSeconds * 1000 + "\nanchor=" + bannerPosition + "\n")
    }

    function writeIdle() {
        const off = displayOffAfter * 60
        let t = "# Written by System Settings → Lock Screen. Edits here get overwritten.\n"
              + "general {\n"
              + "    lock_cmd = pidof hyprlock || hyprlock          # lock screen\n"
              + "    before_sleep_cmd = loginctl lock-session        # lock before suspend\n"
              + "    after_sleep_cmd = hyprctl dispatch dpms on      # turn the display back on after resume\n"
              + "    inhibit_sleep = 3                               # wait until screen is locked\n"
              + "}\n"
        if (off > 0) {
            t += "\n# Dim the screen 30 seconds before it turns off\nlistener {\n    timeout = " + Math.max(30, off - 30)
               + "\n    on-timeout = brightnessctl -s -c backlight set 10%\n    on-resume = brightnessctl -r -c backlight\n}\n"
               + "\n# Turn the display off\nlistener {\n    timeout = " + off
               + "\n    on-timeout = hyprctl dispatch dpms off\n    on-resume = hyprctl dispatch dpms on\n}\n"
            if (lockDelay >= 0)
                t += "\n# Require password\nlistener {\n    timeout = " + (off + lockDelay * 60)
                   + "\n    on-timeout = loginctl lock-session\n}\n"
        }
        sh("printf '%s' \"$2\" > \"$1\" && pkill -x hypridle; setsid -f uwsm-app -- hypridle >/dev/null 2>&1",
           home + "/.config/hypr/hypridle.conf", t)
    }

    // Night Shift schedule: switch on/off when the scheduled state changes,
    // so turning it on or off by hand in between still sticks (like macOS).
    property int lastScheduled: -1
    function inNight(h) { return nightFrom > nightTo ? (h >= nightFrom || h < nightTo) : (h >= nightFrom && h < nightTo) }
    function checkSchedule(force) {
        if (!loaded || !nightSchedule) { lastScheduled = -1; return }
        const on = inNight(new Date().getHours()) ? 1 : 0
        if (force || on !== lastScheduled) Ui.setNightLight(on === 1)
        lastScheduled = on
    }
    Timer { interval: 60000; repeat: true; running: root.loaded && root.nightSchedule; onTriggered: root.checkSchedule(false) }

    function save() {
        const json = JSON.stringify({ clock24h, clockSeconds, clockDate, accent, bannerSeconds, bannerPosition,
                                      displayOffAfter, lockDelay, nightTemp, nightSchedule, nightFrom, nightTo }, null, 2)
        writer.command = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s\\n' \"$2\" > \"$1\"", "sh", jsonPath, json]
        writer.running = true
    }
    Timer { id: saveTimer; interval: 400; onTriggered: root.save() }
    Process { id: writer }

    Process {
        running: true
        command: ["sh", "-c", "cat '" + root.jsonPath + "' 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let saved = {}
                try { saved = JSON.parse(text) } catch (e) {}
                for (const k of Object.keys(saved)) if (k in root) root[k] = saved[k]
                root.loaded = true
                root.checkSchedule(true)
            }
        }
    }
}
