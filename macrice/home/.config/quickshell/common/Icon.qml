import QtQuick

// Nerd Font icon, centred on what's actually drawn. Nerd Font glyphs are wider
// than the space the font reports for them, so a plain Text looks off-centre.
Item {
    id: root
    property string text
    property int size: Theme.iconSize
    property color color: Theme.text

    implicitWidth: Math.max(size, Math.ceil(metrics.tightBoundingRect.width))
    implicitHeight: size

    TextMetrics {
        id: metrics
        font: glyph.font
        text: root.text
    }
    FontMetrics {
        id: fontMetrics
        font: glyph.font
    }

    Text {
        id: glyph
        text: root.text
        color: root.color
        font.family: Theme.iconFont
        font.pixelSize: root.size
        x: Math.round((root.width - metrics.tightBoundingRect.width) / 2 - metrics.tightBoundingRect.x)
        y: Math.round((root.height - metrics.tightBoundingRect.height) / 2 - fontMetrics.ascent - metrics.tightBoundingRect.y)
    }
}
