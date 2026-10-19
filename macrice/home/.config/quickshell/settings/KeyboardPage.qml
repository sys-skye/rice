import QtQuick
import qs.common

Column {
    width: parent ? parent.width : 500

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
