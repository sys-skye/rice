pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Battery charge limit (Asahi macsmc-battery). The kernel stops charging at
// charge_control_end_threshold; asahi-battery restores that value on boot.
// "Charge to full once" lifts it to 100% and puts your limit back once the
// battery is full or you unplug.
Singleton {
    id: root

    readonly property string sysfs: "/sys/class/power_supply/macsmc-battery"
    readonly property string stateFile: Quickshell.statePath("charge-limit")
    readonly property var presets: [60, 70, 80, 90, 100]

    property int threshold: 100     // what the kernel is using right now
    property int limit: 80          // what you picked
    property bool fullOnce: false   // temporarily charging to 100%
    property bool writable: false   // false until setup-charge-limit has run
    property bool loaded: false

    function setLimit(v) {
        limit = v
        fullOnce = false
        apply(v)
        save()
    }
    function chargeFullOnce() {
        fullOnce = true
        apply(100)
        save()
    }
    function cancelFullOnce() { setLimit(limit) }

    function apply(v) {
        // Charging resumes 5% below the limit, so it doesn't top up constantly
        const start = v >= 100 ? 100 : Math.max(0, v - 5)
        writer.command = ["sh", "-c",
            "cd " + sysfs + " && echo " + v + " > charge_control_end_threshold; echo " + start + " > charge_control_start_threshold; true"]
        writer.running = true
    }
    function save() {
        saver.command = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s %s\\n' \"$2\" \"$3\" > \"$1\"",
                         "sh", stateFile, String(limit), fullOnce ? "1" : "0"]
        saver.running = true
    }
    function refresh() { reader.running = true }

    Process {
        id: reader
        running: true
        command: ["sh", "-c", "cat " + root.sysfs + "/charge_control_end_threshold; " +
                  "test -w " + root.sysfs + "/charge_control_end_threshold && echo rw || echo ro; " +
                  "cat '" + root.stateFile + "' 2>/dev/null || echo"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n")
                root.threshold = Number(l[0]) || 100
                root.writable = l[1] === "rw"
                if (!root.loaded) {
                    const saved = (l[2] || "").trim().split(" ")
                    if (Number(saved[0]) > 0) {
                        root.limit = Number(saved[0])
                        root.fullOnce = saved[1] === "1"
                    } else {
                        root.limit = root.threshold   // nothing picked yet: keep what's set
                    }
                    root.loaded = true
                    // Re-apply your limit if something else changed it
                    if (root.writable && !root.fullOnce && root.threshold !== root.limit) root.apply(root.limit)
                }
            }
        }
    }
    Process {
        id: writer
        onExited: root.refresh()
    }
    Process { id: saver }

    // Put the limit back after a one-off full charge
    readonly property real percent: UPower.displayDevice?.percentage ?? 0
    readonly property bool onBattery: UPower.onBattery
    function checkFullOnce() {
        if (fullOnce && (percent >= 0.995 || onBattery)) setLimit(limit)
    }
    onPercentChanged: checkFullOnce()
    onOnBatteryChanged: checkFullOnce()

    // Pick up changes made outside the menu (and the setup script) now and then
    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.refresh() }
}
