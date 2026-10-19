import QtQuick
import Quickshell.Io
import qs.common

Column {
    id: page
    width: parent ? parent.width : 500
    Component.onCompleted: { readKbd.running = true; readLayouts.running = true }

    // Keyboard backlight 0..1
    property real kbd: 0
    Process {
        id: readKbd
        command: ["sh", "-c", "cat /sys/class/leds/kbd_backlight/brightness /sys/class/leds/kbd_backlight/max_brightness"]
        stdout: StdioCollector {
            onStreamFinished: { const v = text.trim().split("\n").map(Number); if (v.length === 2 && v[1] > 0) page.kbd = v[0] / v[1] }
        }
    }
    // Known xkb layout codes, to check what's typed in
    property var knownLayouts: []
    Process {
        id: readLayouts
        command: ["sh", "-c", "awk '/^! layout/ {on=1; next} /^!/ {on=0} on && NF {print $1}' /usr/share/X11/xkb/rules/evdev.lst"]
        stdout: StdioCollector { onStreamFinished: page.knownLayouts = text.trim().split("\n") }
    }
    function layoutsValid(t) { return t !== "" && t.split(",").every(l => page.knownLayouts.indexOf(l) >= 0) }

    Group {
        title: "Keyboard"
        SettingRow {
            label: "Keyboard brightness"
            SettingSlider {
                value: page.kbd
                onMoved: v => { page.kbd = v; Ui.run("brightnessctl -q -d kbd_backlight set " + Math.round(v * 100) + "%") }
            }
        }
        SettingRow {
            label: "Caps Lock key"
            hint: InputSettings.capsLock === "compose" ? "⇪ ' e types é" : ""
            last: true
            Segmented {
                options: [{ label: "Caps Lock", value: "caps" }, { label: "Compose", value: "compose" }, { label: "Escape", value: "escape" },
                          { label: "Control", value: "ctrl" }, { label: "Off", value: "none" }]
                value: InputSettings.capsLock
                onPicked: v => InputSettings.set("capsLock", v)
            }
        }
    }

    Group {
        title: "Input Sources"
        footer: "Layout codes like us, de, gb or fr, separated by commas. With more than one, ⌃Space switches between them. Press ↩ to apply."
        SettingRow {
            label: "Keyboard layouts"
            hint: layoutField.text !== InputSettings.kbLayout && !page.layoutsValid(layoutField.text.replace(/\s/g, "")) ? "Unknown layout" : ""
            last: true
            Rectangle {
                width: 180; height: 28; radius: 6
                color: Theme.fg(0.08)
                border.color: layoutField.activeFocus ? Theme.accent : Theme.panelBorder
                TextInput {
                    id: layoutField
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    text: InputSettings.kbLayout
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    clip: true
                    onAccepted: {
                        const t = text.replace(/\s/g, "")
                        if (page.layoutsValid(t)) InputSettings.set("kbLayout", t)
                    }
                }
            }
        }
    }

    Group {
        title: "Key Repeat"
        footer: "Hold a key in the box below to try it."
        SettingRow {
            label: "Key repeat rate"
            SettingSlider {
                from: 10; to: 80; stepSize: 1; ticks: 8
                minLabel: "Slow"; maxLabel: "Fast"
                value: InputSettings.repeatRate
                onMoved: v => InputSettings.set("repeatRate", Math.round(v))
            }
        }
        SettingRow {
            label: "Delay until repeat"
            SettingSlider {
                // reversed so that right = shorter delay, like macOS
                from: 150; to: 800; stepSize: 10; ticks: 8
                minLabel: "Long"; maxLabel: "Short"
                value: 950 - InputSettings.repeatDelay
                onMoved: v => InputSettings.set("repeatDelay", Math.round(950 - v))
            }
        }
        SettingRow {
            label: "Try it"
            last: true
            Rectangle {
                width: 260; height: 28; radius: 6
                color: Theme.fg(0.08)
                border.color: tryIt.activeFocus ? Theme.accent : Theme.panelBorder
                TextInput {
                    id: tryIt
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    clip: true
                }
            }
        }
    }

    Group {
        title: "Shortcuts"
        SettingRow {
            label: "Keyboard shortcuts"
            hint: "Also on ⌘ /"
            last: true
            LinkButton { text: "Show All…"; onClicked: Ui.openPanel = "keybinds" }
        }
    }
}
