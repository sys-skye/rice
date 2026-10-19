pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Light / Dark / Auto. The shell's colours follow `isDark` (see Theme.qml);
// everything else (GTK apps, kitty, wallpaper…) is switched by scripts/appearance.
Singleton {
    id: root

    property string mode: "dark"          // "light" | "dark" | "auto"
    property int lightFrom: 7             // auto: light from 07:00 …
    property int darkFrom: 19             // … until 19:00
    property bool loaded: false

    property int hour: new Date().getHours()
    readonly property bool isDark: mode === "dark" || (mode === "auto" && (hour >= darkFrom || hour < lightFrom))

    function setMode(m) { mode = m; save() }
    function setTimes(light, dark) { lightFrom = (light + 24) % 24; darkFrom = (dark + 24) % 24; save() }
    function toggle() { setMode(isDark ? "light" : "dark") }

    onIsDarkChanged: if (loaded) apply()
    function apply() {
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/appearance", isDark ? "dark" : "light"])
    }

    // Re-check the clock every minute for Auto
    Timer { interval: 60000; running: root.mode === "auto"; repeat: true; triggeredOnStart: true; onTriggered: root.hour = new Date().getHours() }

    readonly property string file: Quickshell.statePath("appearance.json")
    function save() {
        saver.command = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "sh", file,
                         JSON.stringify({ mode, lightFrom, darkFrom })]
        saver.running = true
    }
    Process { id: saver }
    Process {
        running: true
        command: ["sh", "-c", "cat '" + root.file + "' 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const s = JSON.parse(text)
                    if (s.mode) root.mode = s.mode
                    if (s.lightFrom !== undefined) root.lightFrom = s.lightFrom
                    if (s.darkFrom !== undefined) root.darkFrom = s.darkFrom
                } catch (e) {}
                root.loaded = true
                root.apply()     // make sure apps match after login / restart
            }
        }
    }
}
