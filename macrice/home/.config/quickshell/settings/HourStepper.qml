import QtQuick
import qs.common

// ‹ 19:00 › hour stepper
Row {
    id: stepper
    property int hour
    signal changed(int hour)
    spacing: 4
    LinkButton { text: "‹"; onClicked: stepper.changed(stepper.hour - 1) }
    Label {
        width: 52
        horizontalAlignment: Text.AlignHCenter
        anchors.verticalCenter: parent.verticalCenter
        text: (stepper.hour < 10 ? "0" : "") + stepper.hour + ":00"
        font.features: { "tnum": 1 }
    }
    LinkButton { text: "›"; onClicked: stepper.changed(stepper.hour + 1) }
}
