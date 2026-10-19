pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower

// Battery-saving settings (Settings → Battery → Energy Saver):
// put the Mac to sleep after it has been idle for a while, separately on
// battery and on the power adapter, and pause the cursor trail on battery.
// hypridle still dims, locks and turns the screen off; this adds the sleep.
Singleton {
    id: root

    readonly property string jsonPath: Quickshell.statePath("power-settings.json")
    readonly property var sleepPresets: [0, 10, 15, 30, 60]   // minutes, 0 = never

    property int sleepOnBattery: 15
    property int sleepOnPower: 0
    property bool trailOnBattery: false   // cursor trail keeps a helper polling the cursor
    property bool loaded: false

    readonly property bool onBattery: UPower.onBattery
    readonly property int sleepMinutes: onBattery ? sleepOnBattery : sleepOnPower
    readonly property bool trailAllowed: trailOnBattery || !onBattery

    function set(prop, value) {
        root[prop] = value
        save()
    }
    function save() {
        const json = JSON.stringify({ sleepOnBattery, sleepOnPower, trailOnBattery }, null, 2)
        writer.command = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s\\n' \"$2\" > \"$1\"", "sh", jsonPath, json]
        writer.running = true
    }
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
            }
        }
    }

    // Sleep when idle. Respects idle inhibitors, so playing video keeps it awake.
    IdleMonitor {
        enabled: root.loaded && root.sleepMinutes > 0
        timeout: Math.max(1, root.sleepMinutes) * 60
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) Quickshell.execDetached(["systemctl", "suspend"])
    }
}
