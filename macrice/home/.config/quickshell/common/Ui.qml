pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Small pieces of system state the bar and Control Center share.
Singleton {
    id: root

    // Which dropdown is open ("" = none). Only one at a time, like macOS.
    property string openPanel: ""
    property string lastClosed: ""
    property real lastClosedAt: 0
    // Screen the open dropdown belongs to ("" = whichever screen Hyprland has focused).
    // Set from the bar that was clicked, so a click never depends on Hyprland's focus being up to date.
    property string panelScreen: ""
    onOpenPanelChanged: if (openPanel === "") panelScreen = ""

    function toggle(name, screenName) {
        // A click on the bar that dismissed this same panel shouldn't reopen it
        if (openPanel === "" && lastClosed === name && Date.now() - lastClosedAt < 250) return
        const here = screenName ?? ""
        // Same icon on another screen's bar: move the dropdown there instead of closing it
        if (openPanel === name && (here === "" || here === panelScreen)) { openPanel = ""; return }
        panelScreen = here
        openPanel = name
    }
    // Is the open dropdown meant for this screen?
    function panelOn(screenName, isFocusedScreen) {
        return panelScreen !== "" ? panelScreen === screenName : isFocusedScreen
    }
    function closed(name) {
        if (openPanel !== name) return
        openPanel = ""
        lastClosed = name
        lastClosedAt = Date.now()
    }

    // Mission Control–style window overview
    property bool overviewOpen: false
    property int overviewCommit: 0      // bumped by "swipe down": go to the hovered window

    // System Settings window
    property bool settingsOpen: false
    property string settingsPage: "general"
    function openSettings(page) {
        if (page) settingsPage = page
        openPanel = ""
        settingsOpen = true
    }

    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }
    function launch(cmd) { Quickshell.execDetached(["sh", "-c", "setsid -f uwsm-app -- " + cmd + " >/dev/null 2>&1"]) }

    // Keep awake (idle inhibitor lives in the menu bar)
    property bool keepAwake: false

    // Do Not Disturb (mako mode)
    property bool dnd: false
    function setDnd(on) {
        dnd = on
        run(on ? "makoctl mode -a do-not-disturb" : "makoctl mode -r do-not-disturb")
    }
    Process {
        running: true
        command: ["makoctl", "mode"]
        stdout: StdioCollector { onStreamFinished: root.dnd = text.indexOf("do-not-disturb") >= 0 }
    }

    // Night light (hyprsunset)
    property bool nightLight: false
    function setNightLight(on) {
        nightLight = on
        run(on ? "pkill -x hyprsunset; setsid -f hyprsunset -t " + Prefs.nightTemp + " >/dev/null 2>&1"
               : "pkill -x hyprsunset")
    }
    Process {
        running: true
        command: ["pidof", "hyprsunset"]
        onExited: code => root.nightLight = code === 0
    }

    // Screen brightness 0..1
    property real brightness: 0.5
    property int maxBrightness: 500
    function setBrightness(v) {
        brightness = Math.max(0.01, Math.min(1, v))
        run("brightnessctl -q -c backlight set " + Math.round(brightness * 100) + "%")
    }
    function refreshBrightness() { brightnessProc.running = true }
    Process {
        id: brightnessProc
        running: true
        command: ["sh", "-c", "cat /sys/class/backlight/" + Settings.backlight + "/brightness /sys/class/backlight/" + Settings.backlight + "/max_brightness"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim().split("\n").map(Number)
                if (v.length === 2 && v[1] > 0) { root.maxBrightness = v[1]; root.brightness = v[0] / v[1] }
            }
        }
    }
}
