import QtQuick
import Quickshell
import qs.common

Panel {
    id: root
    name: "stats"
    panelWidth: 270

    component Meter: Column {
        property string title
        property string detail
        property real value
        width: parent.width
        spacing: 5
        Item {
            width: parent.width; height: 16
            Label { x: 4; text: parent.parent.title }
            Label { anchors.right: parent.right; anchors.rightMargin: 4; text: parent.parent.detail; dim: true }
        }
        Rectangle {
            x: 4; width: parent.width - 8; height: 6; radius: 3
            color: Theme.fg(0.12)
            Rectangle {
                width: parent.width * Math.min(1, value); height: parent.height; radius: 3
                color: value > 0.85 ? Theme.red : value > 0.6 ? Theme.orange : Theme.green
                Behavior on width { NumberAnimation { duration: 300 } }
            }
        }
    }

    SectionTitle { text: "System" }
    MenuSeparator {}
    Meter { title: "CPU"; value: Stats.cpu; detail: Math.round(Stats.cpu * 100) + "%" }
    Item { width: 1; height: 4 }
    Meter { title: "Memory"; value: Stats.mem; detail: Stats.memUsed.toFixed(1) + " / " + Stats.memTotal.toFixed(0) + " GB" }
    MenuSeparator {}
    Label { x: 8; height: 22; text: "Temperatures"; dim: true; font.pixelSize: Theme.smallFontSize; font.weight: Font.DemiBold }
    Repeater {
        model: Stats.temps
        delegate: Item {
            required property var modelData
            width: parent.width; height: 22
            Label { x: 8; text: modelData.label; width: parent.width - 70 }
            Label { anchors.right: parent.right; anchors.rightMargin: 8; text: Math.round(modelData.celsius) + " °C"; dim: true }
        }
    }
    MenuSeparator { visible: Stats.fans.length > 0 }
    Label { x: 8; height: 22; visible: Stats.fans.length > 0; text: "Fans"; dim: true; font.pixelSize: Theme.smallFontSize; font.weight: Font.DemiBold }
    Repeater {
        model: Stats.fans
        delegate: Item {
            required property var modelData
            width: parent.width; height: 22
            Label { x: 8; text: modelData.label }
            Label { anchors.right: parent.right; anchors.rightMargin: 8; text: modelData.rpm > 0 ? modelData.rpm + " rpm" : "Off (cool)"; dim: true }
        }
    }
    MenuSeparator {}
    MenuItem {
        text: "Open System Monitor…"
        onClicked: { Ui.openPanel = ""; Ui.launch(Settings.terminal + " --class floating-term btop") }
    }
}
