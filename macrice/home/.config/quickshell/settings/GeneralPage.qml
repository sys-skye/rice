import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

Column {
    id: page
    width: parent ? parent.width : 500
    Component.onCompleted: { about.running = true; time.running = true; updates.running = true }

    // ── About ───────────────────────────────────────────────────────
    property var info: ({})
    Process {
        id: about
        command: ["sh", "-c", "tr -d '\\0' < /proc/device-tree/model; echo; hostname; "
                 + ". /etc/os-release; echo \"$NAME $VERSION_ID\"; uname -r; "
                 + "awk '/MemTotal/ {printf \"%.0f GB\\n\", $2 / 1048576}' /proc/meminfo; "
                 + "df -h --output=avail,size / | tail -1 | awk '{print $1 \" free of \" $2}'; uptime -p | sed 's/^up //'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n")
                page.info = { model: l[0], host: l[1], os: l[2], kernel: l[3], memory: l[4], disk: l[5], uptime: l[6] }
            }
        }
    }
    readonly property string chip: (/M\d+( Pro| Max| Ultra)?/.exec(info.model ?? "") ?? ["Apple Silicon"])[0]

    Group {
        title: "About"
        Item {
            width: parent.width
            height: 76
            Icon { x: 18; anchors.verticalCenter: parent.verticalCenter; text: String.fromCodePoint(0xF0322); size: 42; color: Theme.fg(0.7) }
            Column {
                x: 76; anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Label { text: (page.info.model ?? "").replace(/^Apple /, "").replace(/ \(.*/, "") || "Mac"; bold: true; font.pixelSize: 15 }
                Label { text: (/\((.*)\)/.exec(page.info.model ?? "") ?? ["", ""])[1]; dim: true }
            }
            Rectangle { anchors.bottom: parent.bottom; x: 14; width: parent.width - 28; height: 1; color: Theme.fg(0.07) }
        }
        SettingRow { label: "Name"; Label { text: page.info.host ?? ""; dim: true } }
        SettingRow { label: "Chip"; Label { text: "Apple " + page.chip; dim: true } }
        SettingRow { label: "Memory"; Label { text: page.info.memory ?? ""; dim: true } }
        SettingRow { label: "Storage"; Label { text: page.info.disk ?? ""; dim: true } }
        SettingRow { label: "System"; Label { text: page.info.os ?? ""; dim: true } }
        SettingRow { label: "Kernel"; Label { text: page.info.kernel ?? ""; dim: true } }
        SettingRow { label: "Up for"; last: true; Label { text: page.info.uptime ?? ""; dim: true } }
    }

    // ── Software Update ─────────────────────────────────────────────
    property int updateCount: -1        // -1 = still checking
    Process {
        id: updates
        command: ["sh", "-c", "dnf -q check-update 2>/dev/null | grep -cE '^\\S+\\.\\S+\\s+\\S+\\s+\\S+'"]
        stdout: StdioCollector { onStreamFinished: page.updateCount = Number(text.trim()) || 0 }
    }
    Group {
        title: "Software Update"
        footer: "Opens a terminal that runs dnf (asks for your password) and then updates Flatpak apps."
        SettingRow {
            label: page.updateCount < 0 ? "Checking for updates…"
                 : page.updateCount === 0 ? "Your system is up to date"
                 : page.updateCount + " update" + (page.updateCount === 1 ? "" : "s") + " available"
            hint: "From the last time dnf checked"
            last: true
            LinkButton {
                text: "Update Now…"
                primary: page.updateCount > 0
                onClicked: Ui.launch(Settings.terminal + " sh -c 'sudo dnf upgrade --refresh; flatpak update; echo; read -p \"Done. Press Enter to close.\" x'")
            }
        }
    }

    // ── Date & Time ─────────────────────────────────────────────────
    property var tz: ({})
    Process {
        id: time
        command: ["timedatectl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {}
                for (const line of text.split("\n")) { const i = line.indexOf("="); if (i > 0) o[line.slice(0, i)] = line.slice(i + 1) }
                page.tz = o
            }
        }
    }
    SystemClock { id: clock; precision: SystemClock.Seconds }
    Group {
        title: "Date & Time"
        SettingRow {
            label: "Set time automatically"
            hint: page.tz.NTPSynchronized === "yes" ? "Synced with an internet time server" : "Not synced"
            Toggle {
                checked: page.tz.NTP === "yes"
                onToggled: v => {
                    page.tz = Object.assign({}, page.tz, { NTP: v ? "yes" : "no" })
                    Ui.run("timedatectl set-ntp " + v)
                    time.running = true
                }
            }
        }
        SettingRow {
            label: "Time zone"
            hint: Qt.formatDateTime(clock.date, "dddd d MMMM yyyy, HH:mm:ss")
            last: true
            Label { text: (page.tz.Timezone ?? "").replace(/_/g, " "); dim: true }
        }
    }

    Group {
        title: "Menu Bar Clock"
        footer: "Preview: " + Qt.formatDateTime(clock.date, Prefs.clockFormat).replace(/ {3}/, "  ")
        SettingRow {
            label: "24-hour time"
            Toggle { checked: Prefs.clock24h; onToggled: v => Prefs.set("clock24h", v) }
        }
        SettingRow {
            label: "Show the date"
            Toggle { checked: Prefs.clockDate; onToggled: v => Prefs.set("clockDate", v) }
        }
        SettingRow {
            label: "Show seconds"
            last: true
            Toggle { checked: Prefs.clockSeconds; onToggled: v => Prefs.set("clockSeconds", v) }
        }
    }
}
