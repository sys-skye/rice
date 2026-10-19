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
    // Pixel-exact scales for the current resolution (presets; the slider also allows in-between ones)
    readonly property var scales: [1, 1.25, 1.333333, 1.5, 1.6, 2, 2.5].filter(sc =>
        Math.abs(curWH[0] / sc - Math.round(curWH[0] / sc)) < 0.01 && Math.abs(curWH[1] / sc - Math.round(curWH[1] / sc)) < 0.01)
    function setMode(res, hz) {
        const m = modes.filter(x => x.res === res).sort((a, b) => Math.abs(a.hz - hz) - Math.abs(b.hz - hz))[0]
        if (!m) return
        InputSettings.set("extMode", m.res + "@" + m.hz.toFixed(2))
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
            id: extScaleRow
            visible: page.ext !== null && !InputSettings.extMirror
            label: "Scale"
            hint: Math.round(shown * 100) + "% · Looks like " + Math.round(page.curWH[0] / shown) + " × " + Math.round(page.curWH[1] / shown)
                + (InputSettings.wholePixels(page.curWH[0], page.curWH[1], shown) ? " (sharpest)" : "")
            // Value under the knob while dragging; the screen only rescales on release
            property real dragging: -1
            readonly property real shown: dragging > 0 ? dragging : InputSettings.extScale
            function snap(v) {
                v = Math.round(v * 20) / 20                          // 5% steps (multiples of 1/120, as Wayland wants)
                const exact = page.scales.find(sc => Math.abs(v - sc) < 0.03)
                return exact ?? v                                    // stick to pixel-exact scales like 133%
            }
            SettingSlider {
                from: 1; to: 2.5; ticks: 4
                minLabel: "More Space"; maxLabel: "Larger"
                value: extScaleRow.shown
                onMoved: v => extScaleRow.dragging = extScaleRow.snap(v)
                onReleased: v => {
                    if (extScaleRow.dragging > 0 && Math.abs(extScaleRow.dragging - InputSettings.extScale) > 0.001)
                        InputSettings.set("extScale", extScaleRow.dragging)
                    extScaleRow.dragging = -1
                }
            }
        }
        SettingRow {
            visible: page.ext !== null && !InputSettings.extMirror
            label: "Presets"
            Segmented {
                options: page.scales.map(sc => ({ label: Math.round(sc * 100) + "%", value: sc }))
                value: page.scales.find(sc => Math.abs(sc - InputSettings.extScale) < 0.01)
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
            hint: InputSettings.extMirror ? "" : "Each display has its own Spaces"
            last: true
            Toggle { checked: InputSettings.extMirror; onToggled: v => InputSettings.set("extMirror", v) }
        }
    }

    Group {
        title: "MacBook Display Size"
        footer: "Text size changes GTK apps (Files, Calculator…) and Firefox's toolbars and menus, live. "
              + "Websites keep their own zoom (⌘+ / ⌘−). Display scale resizes everything, including the menu bar and dock — "
              + "100%, 133% and 200% are pixel-exact; other steps can look very slightly softer."
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
            id: scaleRow
            label: "Display scale"
            hint: Math.round(scaleRow.shown * 100) + "% · Looks like " + Math.round(3024 / scaleRow.shown) + " × " + Math.round(1964 / scaleRow.shown)
                + (scaleRow.shown === 2 ? " (Default)" : InputSettings.exactScale(scaleRow.shown) ? " (sharpest)" : "")
            // Value under the knob while dragging; the screen only rescales on release
            property real dragging: -1
            readonly property real shown: dragging > 0 ? dragging : InputSettings.displayScale
            function snap(v) {
                v = Math.round(v * 20) / 20                          // 5% steps (multiples of 1/120, as Wayland wants)
                return Math.abs(v - 1.333333) < 0.03 ? 1.333333 : v  // stick to the pixel-exact 133%
            }
            SettingSlider {
                from: 1; to: 2.5; ticks: 4
                minLabel: "More Space"; maxLabel: "Larger"
                value: scaleRow.shown
                onMoved: v => scaleRow.dragging = scaleRow.snap(v)
                onReleased: v => {
                    if (scaleRow.dragging > 0 && Math.abs(scaleRow.dragging - InputSettings.displayScale) > 0.001)
                        InputSettings.set("displayScale", scaleRow.dragging)
                    scaleRow.dragging = -1
                }
            }
        }
        SettingRow {
            label: "Presets"
            last: true
            Segmented {
                options: [2, 1.75, 1.5, 1.333333, 1].map(sc => ({ label: sc === 2 ? "Default" : Math.round(sc * 100) + "%", value: sc }))
                value: InputSettings.displayScale
                onPicked: v => InputSettings.set("displayScale", v)
            }
        }
    }

    Group {
        title: "Night Shift"
        footer: "Warms up the colours of the screen to make it easier on your eyes at night. "
              + "With a schedule it turns on and off by itself; you can still switch it by hand in between."
        SettingRow {
            label: "Night Shift"
            hint: "Also in Control Center"
            Toggle { checked: Ui.nightLight; onToggled: v => Ui.setNightLight(v) }
        }
        SettingRow {
            label: "Colour temperature"
            hint: Prefs.nightTemp + " K"
            SettingSlider {
                // reversed so that right = warmer
                from: 2500; to: 6000; stepSize: 100; ticks: 8
                minLabel: "Less Warm"; maxLabel: "More Warm"
                value: 8500 - Prefs.nightTemp
                onMoved: v => Prefs.nightTemp = Math.round(8500 - v)
                onReleased: v => Prefs.set("nightTemp", Prefs.nightTemp)
            }
        }
        SettingRow {
            label: "Schedule"
            last: !Prefs.nightSchedule
            Toggle { checked: Prefs.nightSchedule; onToggled: v => Prefs.set("nightSchedule", v) }
        }
        SettingRow {
            visible: Prefs.nightSchedule
            label: "From"
            HourStepper { hour: Prefs.nightFrom; onChanged: h => Prefs.set("nightFrom", (h + 24) % 24) }
        }
        SettingRow {
            visible: Prefs.nightSchedule
            label: "To"
            last: true
            HourStepper { hour: Prefs.nightTo; onChanged: h => Prefs.set("nightTo", (h + 24) % 24) }
        }
    }
}
