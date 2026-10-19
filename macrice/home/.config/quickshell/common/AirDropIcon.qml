import QtQuick

// The AirDrop mark: a dot inside two rings that open at the bottom. Drawn rather
// than a font glyph, whose outline sits low in its box and looked off-centre.
Canvas {
    id: root
    property int size: Theme.iconSize
    property color color: Theme.text

    implicitWidth: size
    implicitHeight: size
    antialiasing: true
    onColorChanged: requestPaint()
    onSizeChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const c = width / 2, s = width / 16
        const gap = 0.42 * Math.PI                       // opening at the bottom
        const from = Math.PI / 2 + gap / 2, to = Math.PI / 2 - gap / 2 + 2 * Math.PI
        ctx.strokeStyle = color
        ctx.fillStyle = color
        ctx.lineCap = "round"
        ctx.lineWidth = 1.5 * s
        for (const r of [4.0 * s, 6.9 * s]) {
            ctx.beginPath()
            ctx.arc(c, c, r, from, to, false)
            ctx.stroke()
        }
        ctx.beginPath()
        ctx.arc(c, c, 1.7 * s, 0, 2 * Math.PI)
        ctx.fill()
    }
}
