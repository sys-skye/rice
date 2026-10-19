import QtQuick

// Charge limit presets + "Charge to Full Now" (used in the battery menu and Settings)
Column {
    spacing: 4

    // Segmented control: 60 70 80 90 100
    Rectangle {
        width: parent.width
        height: 30
        radius: 8
        color: Theme.fg(0.08)
        opacity: ChargeLimit.writable ? 1 : 0.4
        Row {
            anchors.fill: parent
            anchors.margins: 2
            Repeater {
                model: ChargeLimit.presets
                delegate: Rectangle {
                    required property int modelData
                    readonly property bool selected: ChargeLimit.limit === modelData
                    width: parent.width / ChargeLimit.presets.length
                    height: parent.height
                    radius: 6
                    color: selected ? Theme.accent : segMouse.containsMouse ? Theme.hover : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Label {
                        anchors.centerIn: parent
                        text: modelData + "%"
                        bold: parent.selected
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: segMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: ChargeLimit.writable
                        onClicked: ChargeLimit.setLimit(modelData)
                    }
                }
            }
        }
    }

    Item { width: 1; height: 2 }

    // Charge to full once / cancel
    Rectangle {
        visible: ChargeLimit.writable && (ChargeLimit.limit < 100 || ChargeLimit.fullOnce)
        width: parent.width
        height: 32
        radius: 8
        color: ChargeLimit.fullOnce ? Theme.fg(0.08) : fullMouse.containsMouse ? Qt.lighter(Theme.accent, 1.15) : Theme.accent
        Row {
            anchors.centerIn: parent
            spacing: 6
            Icon { anchors.verticalCenter: parent.verticalCenter; text: Glyphs.batteryCharging; size: 15 }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: ChargeLimit.fullOnce ? "Cancel Full Charge" : "Charge to Full Now"
                bold: true
            }
        }
        MouseArea {
            id: fullMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: ChargeLimit.fullOnce ? ChargeLimit.cancelFullOnce() : ChargeLimit.chargeFullOnce()
        }
    }
    Label {
        x: 4
        width: parent.width - 8
        visible: ChargeLimit.fullOnce
        text: "Charging to 100% — your " + ChargeLimit.limit + "% limit comes back when it's full or unplugged."
        dim: true
        font.pixelSize: Theme.smallFontSize
        wrapMode: Text.Wrap
        elide: Text.ElideNone
    }

    // Not set up yet
    Label {
        x: 4
        width: parent.width - 8
        visible: !ChargeLimit.writable
        text: "One-time setup needed. In a terminal run:\n~/.config/hypr/scripts/setup-charge-limit"
        dim: true
        font.pixelSize: Theme.smallFontSize
        wrapMode: Text.Wrap
        elide: Text.ElideNone
    }
}
