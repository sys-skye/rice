pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU / memory / temperature sampling every 2 seconds.
Singleton {
    id: root
    property real cpu: 0          // 0..1
    property real memUsed: 0      // GiB
    property real memTotal: 0     // GiB
    property real mem: 0          // 0..1
    property var temps: []        // [{ label, celsius }]
    property var fans: []         // [{ label, rpm, max }]
    property var _prevCpu: null

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: sampler.running = true
    }

    Process {
        id: sampler
        command: ["sh", "-c",
            "head -1 /proc/stat; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo; " +
            "for f in /sys/class/hwmon/hwmon*/temp*_label; do [ -f \"$f\" ] && printf 'T\\t%s\\t%s\\n' \"$(cat $f)\" \"$(cat ${f%_label}_input)\"; done; " +
            "for f in /sys/class/hwmon/hwmon*/fan*_input; do [ -f \"$f\" ] && printf 'F\\t%s\\t%s\\t%s\\n' \"$(cat ${f%_input}_label)\" \"$(cat $f)\" \"$(cat ${f%_input}_max)\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                const c = lines[0].split(/\s+/).slice(1).map(Number)
                const idle = c[3] + c[4], total = c.reduce((a, b) => a + b, 0)
                if (root._prevCpu) {
                    const dt = total - root._prevCpu.total, di = idle - root._prevCpu.idle
                    if (dt > 0) root.cpu = 1 - di / dt
                }
                root._prevCpu = { total: total, idle: idle }
                let memTotal = 0, memAvail = 0
                const temps = []
                const fans = []
                for (const l of lines.slice(1)) {
                    if (l.startsWith("MemTotal")) memTotal = Number(l.split(/\s+/)[1])
                    else if (l.startsWith("MemAvailable")) memAvail = Number(l.split(/\s+/)[1])
                    else if (l.startsWith("F\t")) {
                        const p = l.split("\t")
                        fans.push({ label: p[1], rpm: Number(p[2]), max: Number(p[3]) })
                    }
                    else if (l.startsWith("T\t")) {
                        const p = l.split("\t")
                        if (p[1] !== "Composite" && p[1] !== "temp") temps.push({ label: p[1], celsius: Number(p[2]) / 1000 })
                    }
                }
                root.memTotal = memTotal / 1048576
                root.memUsed = (memTotal - memAvail) / 1048576
                root.mem = memTotal > 0 ? (memTotal - memAvail) / memTotal : 0
                root.temps = temps
                root.fans = fans
            }
        }
    }
}
