import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

Column {
    id: page
    width: parent ? parent.width : 500
    Component.onCompleted: { Ui.refreshBrightness(); readText.running = true; readMonitors.running = true }

    // External monitor info (name, modes…) from Hyprland
    property var ext: null
    Process {
        id: readMonitors
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const all = JSON.parse(text)
                    page.ext = all.find(m => m.name === InputSettings.extName) ?? null
                    if (page.ext) InputSettings.extSize = [page.ext.width, page.ext.height]
                } catch (e) {}
            }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: readMonitors.running = true }   // plug/unplug

    // Modes like "2560x1440@144.00Hz" → { res: "2560x1440", w, h, hz }
    readonly property var modes: (ext?.availableModes ?? []).map(m => {
        const r = /^(\d+)x(\d+)@([\d.]+)Hz$/.exec(m)
        return r ? { res: r[1] + "x" + r[2], w: Number(r[1]), h: Number(r[2]), hz: Number(r[3]) } : null
    }).filter(m => m)
    readonly property var resolutions: [...new Set(modes.map(m => m.res))]
        .sort((a, b) => { const [aw, ah] = a.split("x").map(Number), [bw, bh] = b.split("x").map(Number); return bw * bh - aw * ah })
    readonly property string curRes: InputSettings.extMode ? InputSettings.extMode.split("@")[0] : (ext ? ext.width + "x" + ext.height : "")
    readonly property real curHz: InputSettings.extMode ? Number(InputSettings.extMode.split("@")[1]) : (ext?.refreshRate ?? 60)
    readonly property var rates: [...new Set(modes.filter(m => m.res === curRes).map(m => Math.round(m.hz)))].sort((a, b) => b - a)
    readonly property var curWH: curRes ? curRes.split("x").map(Number) : [2560, 1440]
    // Only scales that divide the screen into whole pixels (Hyprland's rule)
    readonly property var scales: [1, 1.25, 1.333333, 1.5, 1.6, 2].filter(sc =>
        Math.abs(curWH[0] / sc - Math.round(curWH[0] / sc)) < 0.01 && Math.abs(curWH[1] / sc - Math.round(curWH[1] / sc)) < 0.01)
    function setMode(res, hz) {
        const m = modes.filter(x => x.res === res).sort((a, b) => Math.abs(a.hz - hz) - Math.abs(b.hz - hz))[0]
        if (!m) return
        InputSettings.set("extMode", m.res + "@" + m.hz.toFixed(2))
        // keep the scale valid for the new resolution
        if (!scales.some(sc => Math.abs(sc - InputSettings.extScale) < 0.01)) InputSettings.set("extScale", 1)
    }

    // GTK's text scaling factor: GTK apps and Firefox follow it live
    property real textScale: 1
    Process {
        id: readText
        command: ["gsettings", "get", "org.gnome.desktop.interface", "text-scaling-factor"]
        stdout: StdioCollector { onStreamFinished: page.textScale = Number(text.trim()) || 1 }
    }
    function setText(v) {
        textScale = Math.round(v * 20) / 20
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "text-scaling-factor", textScale.toFixed(2)])
    }

    Group {
        title: "MacBook Display"
        footer: "Built-in Liquid Retina XDR · 3024 × 1964."
        SettingRow {
            label: "Brightness"
            SettingSlider {
                from: 0.01; to: 1
                value: Ui.brightness
                onMoved: v => Ui.setBrightness(v)
            }
        }
        SettingRow {
            label: "Night Shift"
            hint: "Warmer colours, easier on the eyes at night"
            last: true
            Toggle { checked: Ui.nightLight; onToggled: v => Ui.setNightLight(v) }
        }
    }

    Group {
        title: page.ext ? "External Display · " + (page.ext.model || page.ext.description) : "External Display"
        footer: page.ext ? "Arrangement is relative to the MacBook's screen. Changes apply instantly."
                         : "Connect a display to the HDMI port to set it up here. (USB-C displays aren't supported by Asahi yet.)"
        visible: true

        // Arrangement preview: laptop + external screen, drawn to scale
        Item {
            id: preview
            visible: page.ext !== null && !InputSettings.extMirror
            width: parent.width
            height: 150
            readonly property real lw: 3024 / InputSettings.displayScale
            readonly property real lh: 1964 / InputSettings.displayScale
            readonly property real ew: page.curWH[0] / InputSettings.extScale
            readonly property real eh: page.curWH[1] / InputSettings.extScale
            readonly property string pos: InputSettings.extPosition
            readonly property real totalW: pos === "left" || pos === "right" ? lw + ew : Math.max(lw, ew)
            readonly property real totalH: pos === "above" || pos === "below" ? lh + eh : Math.max(lh, eh)
            readonly property real k: Math.min((width - 40) / totalW, (height - 24) / totalH)
            Item {
                anchors.centerIn: parent
                width: preview.totalW * preview.k
                height: preview.totalH * preview.k
                Rectangle {   // laptop
                    x: preview.pos === "left" ? preview.ew * preview.k + 4 : (preview.pos === "above" || preview.pos === "below") ? (parent.width - width) / 2 : 0
                    y: preview.pos === "above" ? preview.eh * preview.k + 4 : 0
                    width: preview.lw * preview.k; height: preview.lh * preview.k
                    radius: 4; color: Theme.fg(0.14); border.color: Theme.fg(0.3)
                    Label { anchors.centerIn: parent; text: "MacBook"; font.pixelSize: 11; dim: true }
                    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: parent.width * 0.16; height: 3; color: Theme.fg(0.4) }
                }
                Rectangle {   // external
                    x: preview.pos === "right" ? preview.lw * preview.k + 4 : (preview.pos === "above" || preview.pos === "below") ? (parent.width - width) / 2 : 0
                    y: preview.pos === "below" ? preview.lh * preview.k + 4 : 0
                    width: preview.ew * preview.k; height: preview.eh * preview.k
                    radius: 4; color: Qt.rgba(0.04, 0.52, 1, 0.25); border.color: Theme.accent
                    Label { anchors.centerIn: parent; text: page.ext?.model ?? "Display"; font.pixelSize: 11 }
                }
            }
        }
        SettingRow {
            visible: page.ext !== null && !InputSettings.extMirror
            label: "Position"
            Segmented {
                options: [{ label: "Left", value: "left" }, { label: "Right", value: "right" },
                          { label: "Above", value: "above" }, { label: "Below", value: "below" }]
                value: InputSettings.extPosition
                onPicked: v => InputSettings.set("extPosition", v)
            }
        }
        SettingRow {
            visible: page.ext !== null
            label: "Resolution"
            hint: page.resolutions.indexOf(page.curRes) === 0 ? "Native (sharpest)" : ""
            Row {
                spacing: 4
                readonly property int i: page.resolutions.indexOf(page.curRes)
                LinkButton { text: "‹"; visible: parent.i > 0; onClicked: page.setMode(page.resolutions[parent.i - 1], page.curHz) }
                Label {
                    width: 104
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: page.curRes.replace("x", " × ")
                }
                LinkButton { text: "›"; visible: parent.i < page.resolutions.length - 1; onClicked: page.setMode(page.resolutions[parent.i + 1], page.curHz) }
            }
        }
        SettingRow {
            visible: page.ext !== null && page.rates.length > 1
            label: "Refresh rate"
            Segmented {
                options: page.rates.map(hz => ({ label: hz + " Hz", value: hz }))
                value: Math.round(page.curHz)
                onPicked: v => page.setMode(page.curRes, v)
            }
        }
        SettingRow {
            visible: page.ext !== null && !InputSettings.extMirror
            label: "Scale"
            hint: "Looks like " + Math.round(page.curWH[0] / InputSettings.extScale) + " × " + Math.round(page.curWH[1] / InputSettings.extScale)
            Segmented {
                options: page.scales.map(sc => ({ label: Math.round(sc * 100) + "%", value: sc }))
                value: page.scales.find(sc => Math.abs(sc - InputSettings.extScale) < 0.01) ?? 1
                onPicked: v => InputSettings.set("extScale", v)
            }
        }
        SettingRow {
            visible: page.ext !== null
            label: "Show the Dock on"
            Segmented {
                options: [{ label: "MacBook", value: "builtin" }, { label: "External", value: "external" }]
                value: InputSettings.mainDisplay
                onPicked: v => InputSettings.set("mainDisplay", v)
            }
        }
        SettingRow {
            visible: page.ext !== null
            label: "Mirror the MacBook's screen"
            Toggle { checked: InputSettings.extMirror; onToggled: v => InputSettings.set("extMirror", v) }
        }
        SettingRow {
            visible: page.ext !== null && !InputSettings.extMirror
            label: "Displays have separate Spaces"
            hint: InputSettings.separateSpaces ? "⌘1–9 jumps to the screen that has that Space"
                                               : "Off: Spaces are shared, ⌘1–9 brings a Space to the screen you're on"
            last: true
            Toggle { checked: InputSettings.separateSpaces; onToggled: v => InputSettings.set("separateSpaces", v) }
        }
    }

    Group {
        title: "MacBook Display Size"
        footer: "Text size changes GTK apps (Files, Calculator…) and Firefox's toolbars and menus, live. "
              + "Websites keep their own zoom (⌘+ / ⌘−). Display scale resizes everything, including the menu bar and dock."
        SettingRow {
            label: "Text size"
            hint: Math.round(page.textScale * 100) + "%"
            SettingSlider {
                from: 0.75; to: 1.25; stepSize: 0.05; ticks: 11
                minLabel: "Smaller"; maxLabel: "Larger"
                value: page.textScale
                onMoved: v => page.setText(v)
            }
        }
        SettingRow {
            label: "Display scale"
            hint: InputSettings.displayScale > 1.9 ? "Looks like 1512 × 982" : "Looks like 2268 × 1473 (everything about a third smaller)"
            last: true
            Segmented {
                options: [{ label: "Default", value: 2 }, { label: "More Space", value: 1.333333 }]
                value: InputSettings.displayScale > 1.9 ? 2 : 1.333333
                onPicked: v => InputSettings.set("displayScale", v)
            }
        }
    }
}
