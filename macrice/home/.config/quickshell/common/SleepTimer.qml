pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// "Sleep in N minutes" (Control Center). Runs as a systemd user timer, so it
// survives shell restarts; a second timer warns one minute before. When it
// ends, scripts/sleep-timer-end locks + turns the screen off (keys/mouse wake
// it) and only really suspends after 15 untouched minutes.
Singleton {
    id: root

    readonly property var presets: [15, 30, 45, 60, 90, 120]
    readonly property string stateFile: Quickshell.statePath("sleep-timer")
    readonly property string endScript: Quickshell.env("HOME") + "/.config/hypr/scripts/sleep-timer-end"
    property real endsAt: 0                    // epoch ms, 0 = off
    // Plain property updated by tick(): a binding on Date.now() never
    // re-evaluates, so the timer used to stay "active" at 0m after it fired.
    property bool active: false
    property int minutesLeft: 0
    property int chosen: 0                     // preset you picked (for highlighting)

    function start(minutes) {
        chosen = minutes
        endsAt = Date.now() + minutes * 60000
        Quickshell.execDetached(["sh", "-c",
            "systemctl --user stop sleep-timer.timer sleep-timer.service sleep-timer-warn.timer 2>/dev/null; " +
            "systemd-run --user --quiet --timer-property=AccuracySec=1s --unit=sleep-timer --on-active=" + minutes + "m " + endScript + "; " +
            (minutes > 1 ? "systemd-run --user --quiet --timer-property=AccuracySec=1s --unit=sleep-timer-warn --on-active=" + (minutes - 1) + "m " +
             "notify-send -a 'Sleep Timer' -i weather-clear-night 'Going to sleep in 1 minute' 'Cancel it in Control Center'; " : "") +
            "printf '%s' " + Math.round(endsAt) + " > '" + stateFile + "'"])
        tick()
    }
    function cancel() {
        chosen = 0
        endsAt = 0
        active = false
        minutesLeft = 0
        Quickshell.execDetached(["sh", "-c", "systemctl --user stop sleep-timer.timer sleep-timer.service sleep-timer-warn.timer 2>/dev/null; rm -f '" + stateFile + "'"])
    }
    function tick() {
        active = endsAt > Date.now()
        minutesLeft = active ? Math.max(1, Math.ceil((endsAt - Date.now()) / 60000)) : 0
        if (endsAt && !active) { endsAt = 0; chosen = 0 }
    }

    Timer { interval: 5000; running: root.endsAt > 0; repeat: true; onTriggered: root.tick() }

    // Pick up a timer that was set before the shell (re)started
    Process {
        running: true
        command: ["sh", "-c", "systemctl --user is-active --quiet sleep-timer.timer && cat '" + root.stateFile + "' 2>/dev/null || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: { root.endsAt = Number(text.trim()) || 0; root.tick() }
        }
    }
}
