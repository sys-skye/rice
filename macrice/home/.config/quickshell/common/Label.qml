import QtQuick

Text {
    property bool bold: false
    property bool dim: false
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    font.weight: bold ? Font.DemiBold : Font.Normal
    color: dim ? Theme.textDim : Theme.text
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
}
