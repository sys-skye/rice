pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The cursor theme + size live in GNOME's settings (what GTK Settings / nwg-look edit).
// Whenever they change, apply them to Hyprland and apps via scripts/cursor-apply.
Singleton {
    id: root

    property string theme: "Adwaita"
    property int size: 24
    property var themes: []           // installed cursor themes
    property bool ready: false

    function setTheme(t) { Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "cursor-theme", t]) }
    function setSize(s) { Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "cursor-size", String(Math.round(s))]) }
    function start() { ready = true }

    Timer {
        id: applyLater
        interval: 250
        onTriggered: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/cursor-apply", root.theme, String(root.size)])
    }

    // Current values at startup (and apply them, so Hyprland matches after login)
    Process {
        running: root.ready
        command: ["sh", "-c", "gsettings get org.gnome.desktop.interface cursor-theme; gsettings get org.gnome.desktop.interface cursor-size; " +
                  "for d in /usr/share/icons/* \"$HOME\"/.local/share/icons/* \"$HOME\"/.icons/*; do [ -d \"$d/cursors\" ] && basename \"$d\"; done | sort -u | grep -v '^default$'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n")
                root.theme = l[0].replace(/'/g, "")
                root.size = Number(l[1]) || 24
                root.themes = l.slice(2)
                applyLater.restart()
            }
        }
    }
    // Live changes from any settings app
    Process {
        running: root.ready
        command: ["gsettings", "monitor", "org.gnome.desktop.interface"]
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/^(cursor-theme|cursor-size):\s*'?([^']*)'?$/)
                if (!m) return
                if (m[1] === "cursor-theme") root.theme = m[2]
                else root.size = Number(m[2])
                applyLater.restart()
            }
        }
    }
}
