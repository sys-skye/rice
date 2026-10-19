import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.common

Panel {
    id: root
    name: "sound"
    panelWidth: 290

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var nodes: Pipewire.nodes.values.filter(n => n.audio && !n.isStream)
    readonly property var outputs: nodes.filter(n => n.isSink)
    readonly property var inputs: nodes.filter(n => !n.isSink && !(n.name || "").endsWith(".monitor"))

    PwObjectTracker { objects: [root.sink, Pipewire.defaultAudioSource] }

    SectionTitle { text: "Sound" }
    Item {
        width: parent.width
        height: 34
        Slider {
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            icon: Glyphs.volumeIcon(value, root.sink?.audio?.muted ?? false)
            value: root.sink?.audio?.volume ?? 0
            onMoved: v => { if (root.sink?.audio) { root.sink.audio.muted = false; root.sink.audio.volume = v } }
        }
    }

    MenuSeparator {}
    Label { x: 8; height: 22; text: "Output"; dim: true; font.pixelSize: Theme.smallFontSize; font.weight: Font.DemiBold }
    Repeater {
        model: root.outputs
        delegate: ListRow {
            required property var modelData
            icon: /head|blue|bt/i.test(modelData.name + modelData.description) ? Glyphs.headphones : Glyphs.speaker
            text: modelData.nickname || modelData.description || modelData.name
            highlighted: modelData === root.sink
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }

    Label { x: 8; height: 22; visible: root.inputs.length > 0; text: "Input"; dim: true; font.pixelSize: Theme.smallFontSize; font.weight: Font.DemiBold }
    Repeater {
        model: root.inputs
        delegate: MenuItem {
            required property var modelData
            text: modelData.nickname || modelData.description || modelData.name
            checked: modelData === Pipewire.defaultAudioSource
            onClicked: Pipewire.preferredDefaultAudioSource = modelData
        }
    }

    MenuSeparator {}
    MenuItem {
        text: "Sound Settings…"
        onClicked: { Ui.openPanel = ""; Ui.launch("pavucontrol") }
    }
}
