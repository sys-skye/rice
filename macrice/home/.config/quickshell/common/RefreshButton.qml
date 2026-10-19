import QtQuick

// Small circular ↻ button. Spins while `busy` (and for at least one turn per press).
Item {
    id: root
    property bool busy: false
    signal clicked()

    implicitWidth: 24
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: mouse.pressed ? Theme.fg(0.22) : mouse.containsMouse ? Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    // Drawn rather than a font glyph: the ↻ glyph isn't centred in its box, so it wobbled when spun.
    // Here the arc's centre is exactly the item's centre, which is what it rotates around.
    Canvas {
        id: glyph
        anchors.centerIn: parent
        width: 16
        height: 16
        antialiasing: true
        smooth: true
        readonly property color tint: Theme.textDim
        onTintChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const c = width / 2, r = 5.5
            const a0 = -Math.PI / 3, a1 = a0 + 2 * Math.PI - 1.0   // clockwise, gap at the top
            ctx.strokeStyle = tint
            ctx.fillStyle = tint
            ctx.lineWidth = 1.6
            ctx.lineCap = "round"
            ctx.beginPath()
            ctx.arc(c, c, r, a0, a1, false)
            ctx.stroke()
            // Arrowhead at the end of the arc, pointing along it
            const px = c + r * Math.cos(a1), py = c + r * Math.sin(a1)
            const dx = -Math.sin(a1), dy = Math.cos(a1)    // clockwise tangent
            const nx = Math.cos(a1), ny = Math.sin(a1)     // outward
            ctx.beginPath()
            ctx.moveTo(px + dx * 2.8, py + dy * 2.8)
            ctx.lineTo(px - dx * 0.8 + nx * 2.6, py - dy * 0.8 + ny * 2.6)
            ctx.lineTo(px - dx * 0.8 - nx * 2.6, py - dy * 0.8 - ny * 2.6)
            ctx.closePath()
            ctx.fill()
        }
        RotationAnimation on rotation {
            running: root.busy || minSpin.running
            loops: Animation.Infinite
            from: 0; to: 360
            duration: 800
            onRunningChanged: if (!running) glyph.rotation = 0
        }
    }
    Timer { id: minSpin; interval: 800 }
    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { minSpin.restart(); root.clicked() }
    }
}
