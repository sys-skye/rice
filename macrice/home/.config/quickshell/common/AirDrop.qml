pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// AirDrop through omdrop (~/.local/bin/omdrop, radio = omdrop-awdl's patched brcmfmac).
// State comes from `omdrop status --json`; nearby devices from `omdrop peers --json`.
Singleton {
    id: root

    readonly property string cmd: Quickshell.env("HOME") + "/.local/bin/omdrop"

    property bool available: false      // omdrop is installed and answered
    property bool receiving: false
    property int remaining: 0           // seconds left in the window (timed mode)
    property string mode: ""            // timed | once | forever
    property string deviceName: ""
    property string visibility: "everyone"
    property string dir: ""
    property bool busy: false           // an on/off/visibility command is running

    // How long "on" lasts: once | 10m | 1h | forever
    property string duration: "10m"

    // Nearby devices: [{ mac, rssi, name }]. Names are remembered per address,
    // because only the slower `peers -n` asks devices for them.
    property var peers: []
    property var names: ({})
    property bool scanning: false
    property bool watchingPeers: false  // the dropdown is open

    // Sending
    property string sendingTo: ""       // mac of the device a send is going to
    property string sendStatus: ""      // last line from omdrop send, in words

    readonly property string summary: !receiving ? "Off"
        : (visibility === "contacts" ? "Contacts Only" : "Everyone")
          + (mode === "once" ? " · 1 file" : mode === "forever" ? "" : remaining > 0 ? " · " + Math.ceil(remaining / 60) + " min" : "")

    // Fits a Control Center tile
    readonly property string shortSummary: !receiving ? "Off"
        : mode === "once" ? "Until 1 file" : mode === "forever" ? (visibility === "contacts" ? "Contacts Only" : "Everyone")
        : remaining > 0 ? Math.ceil(remaining / 60) + " min left" : "On"

    function refresh() { if (!statusProc.running) statusProc.running = true }

    function setOn(on) {
        if (busy) return
        busy = true
        receiving = on   // optimistic; the next status read corrects it
        if (on) run(["on", duration === "forever" ? "forever" : duration])
        else run(["off"])
    }
    function toggle() { setOn(!receiving) }
    function setDuration(d) {
        duration = d
        if (receiving) { busy = true; run(["on", d]) }   // restart the window with the new length
    }
    function setVisibility(v) {
        visibility = v
        busy = true
        run(["visibility", v])
    }
    function openDownloads() { Quickshell.execDetached(["xdg-open", dir || Quickshell.env("HOME") + "/Downloads"]) }

    function scanPeers(withNames) {
        if (!receiving) { peers = []; return }
        if (withNames) {
            if (namesProc.running) return
            scanning = true
            namesProc.running = true
        } else if (!peersProc.running) peersProc.running = true
    }

    // Opens a file chooser, then sends the chosen files as one transfer
    function sendTo(mac) {
        if (sendProc.running) return
        sendingTo = mac
        sendStatus = "Choose files…"
        sendProc.command = [cmd, "send", "--pick", "--to", mac]
        sendProc.running = true
    }
    function cancelSend() { if (sendProc.running) sendProc.signal(15) }

    function nameOf(p) { return p.name || names[p.mac] || "" }
    // "iPhone", "MacBookPro18,3"… when the device has sent us something
    property var models: ({})
    function modelOf(p) { return models[p.mac] || "" }

    // fe80::a082:42ff:fe87:3533 → a2:82:42:87:35:33 (EUI-64 back to the MAC the peer list uses)
    function macFromLinkLocal(addr) {
        const g = addr.replace(/^fe80::/i, "").split("%")[0].split(":")
        if (g.length !== 4) return ""
        const b = g.map(x => x.padStart(4, "0")).join("").match(/../g)
        if (b[3] !== "ff" || b[4] !== "fe") return ""
        b[0] = (parseInt(b[0], 16) ^ 0x02).toString(16).padStart(2, "0")
        return [b[0], b[1], b[2], b[5], b[6], b[7]].join(":")
    }
    // The receiver logs "ask from NAME (MODEL): …" then '<addr> "POST /Ask …"'
    property var pendingAsk: null
    function readReceiverLog(line) {
        let m = line.match(/ask from (.*) \(([^)]*)\): /)
        if (m) { pendingAsk = { name: m[1], model: m[2] }; return }
        m = line.match(/(fe80::[0-9a-f:]+)[^ ]* "POST \/Ask/i)
        if (m && pendingAsk) {
            const mac = macFromLinkLocal(m[1])
            if (mac) {
                const n = Object.assign({}, names); n[mac] = pendingAsk.name; names = n
                const md = Object.assign({}, models); md[mac] = pendingAsk.model; models = md
            }
            pendingAsk = null
        }
    }
    Process {
        running: root.available
        command: ["journalctl", "--user", "-u", "airdrop-receiver", "-f", "-n", "500", "-o", "cat", "--no-pager"]
        stdout: SplitParser { onRead: line => root.readReceiverLog(line) }
    }

    function run(args) {
        actionProc.command = [cmd].concat(args)
        actionProc.running = true
    }

    function applyPeers(text) {
        try {
            const list = JSON.parse(text)
            const n = Object.assign({}, names)
            for (const p of list) if (p.name) n[p.mac] = p.name
            names = n
            peers = list.sort((a, b) => b.rssi - a.rssi)
        } catch (e) {}
    }

    Process {
        id: statusProc
        command: [root.cmd, "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const s = JSON.parse(text)
                    root.available = true
                    root.receiving = s.receiving
                    root.remaining = s.remaining ?? 0
                    root.mode = s.mode ?? ""
                    root.deviceName = s.name ?? ""
                    root.visibility = s.visibility ?? "everyone"
                    root.dir = s.dir ?? ""
                    if (!root.receiving) root.peers = []
                } catch (e) { root.available = false }
            }
        }
        onExited: code => { if (code === 127) root.available = false }
    }

    Process {
        id: actionProc
        onExited: { root.busy = false; root.refresh() }
    }

    Process {
        id: peersProc
        command: [root.cmd, "peers", "--json"]
        stdout: StdioCollector { onStreamFinished: root.applyPeers(text) }
    }
    Process {
        id: namesProc
        command: ["timeout", "45", root.cmd, "peers", "-n", "--json"]
        stdout: StdioCollector { onStreamFinished: root.applyPeers(text) }
        onExited: root.scanning = false
    }

    Process {
        id: sendProc
        stdout: SplitParser { onRead: line => { if (line.trim()) root.sendStatus = line.trim() } }
        stderr: SplitParser { onRead: line => { if (line.trim()) root.sendStatus = line.trim() } }
        onExited: code => {
            if (code !== 0 && /Choose files/.test(root.sendStatus)) root.sendStatus = ""   // chooser cancelled
            clearSend.restart()
        }
    }
    Timer { id: clearSend; interval: 6000; onTriggered: { root.sendingTo = ""; root.sendStatus = "" } }

    // Status: quickly while on or while the dropdown is open, slowly otherwise
    Timer {
        running: true
        repeat: true
        triggeredOnStart: true
        interval: root.receiving || root.watchingPeers ? 3000 : 20000
        onTriggered: root.refresh()
    }
    // Nearby list while the dropdown is open
    Timer {
        running: root.watchingPeers && root.receiving
        repeat: true
        triggeredOnStart: true
        interval: 3000
        onTriggered: root.scanPeers(false)
    }
    readonly property bool sending: sendProc.running
}
