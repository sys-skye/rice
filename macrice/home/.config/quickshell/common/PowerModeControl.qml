import QtQuick
import Quickshell.Services.UPower

// Low Power / Balanced / Performance (power-profiles via Fedora's tuned-ppd)
Rectangle {
    id: root
    readonly property var modes: [
        { label: "Low Power", value: PowerProfile.PowerSaver },
        { label: "Balanced", value: PowerProfile.Balanced },
    ].concat(PowerProfiles.hasPerformanceProfile ? [{ label: "Performance", value: PowerProfile.Performance }] : [])

    width: parent ? parent.width : 260
    height: 30
    radius: 8
    color: Theme.fg(0.08)
    Row {
        anchors.fill: parent
        anchors.margins: 2
        Repeater {
            model: root.modes
            delegate: Rectangle {
                required property var modelData
                readonly property bool selected: PowerProfiles.profile === modelData.value
                width: parent.width / root.modes.length
                height: parent.height
                radius: 6
                color: selected ? (modelData.value === PowerProfile.PowerSaver ? Theme.yellow : Theme.accent)
                                : mouse.containsMouse ? Theme.hover : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                Label { anchors.centerIn: parent; text: modelData.label; font.pixelSize: 12; bold: parent.selected }
                MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: PowerProfiles.profile = modelData.value }
            }
        }
    }
}
