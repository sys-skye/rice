import QtQuick
import Quickshell.Services.Pipewire
import qs.common

Column {
    width: parent ? parent.width : 500
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var outputs: Pipewire.nodes.values.filter(n => n.audio && !n.isStream && n.isSink)
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var inputs: Pipewire.nodes.values.filter(n => n.audio && !n.isStream && !n.isSink)
    PwObjectTracker { objects: [sink, source] }

    Group {
        title: "Output"
        SettingRow {
            label: "Output volume"
            SettingSlider {
                value: sink?.audio?.volume ?? 0
                onMoved: v => { if (sink?.audio) { sink.audio.muted = false; sink.audio.volume = v } }
            }
        }
        SettingRow {
            label: "Mute"
            Toggle { checked: sink?.audio?.muted ?? false; onToggled: v => { if (sink?.audio) sink.audio.muted = v } }
        }
        Repeater {
            model: outputs
            delegate: SettingRow {
                required property var modelData
                required property int index
                label: modelData.nickname || modelData.description || modelData.name
                last: index === outputs.length - 1
                Icon { visible: modelData === sink; text: Glyphs.check; color: Theme.accent }
                LinkButton { visible: modelData !== sink; text: "Use"; onClicked: Pipewire.preferredDefaultAudioSink = modelData }
            }
        }
    }
    Group {
        title: "Input"
        SettingRow {
            label: "Input volume"
            SettingSlider {
                value: source?.audio?.volume ?? 0
                // wpctl: Quickshell can't set the volume of the mono built-in mic
                onMoved: v => Ui.run("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0; wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + v.toFixed(2))
            }
        }
        SettingRow {
            label: "Mute microphone"
            last: inputs.length === 0
            Toggle { checked: source?.audio?.muted ?? false; onToggled: v => Ui.run("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ " + (v ? 1 : 0)) }
        }
        Repeater {
            model: inputs
            delegate: SettingRow {
                required property var modelData
                required property int index
                label: modelData.nickname || modelData.description || modelData.name
                last: index === inputs.length - 1
                Icon { visible: modelData === source; text: Glyphs.check; color: Theme.accent }
                LinkButton { visible: modelData !== source; text: "Use"; onClicked: Pipewire.preferredDefaultAudioSource = modelData }
            }
        }
    }
    Group {
        title: "Advanced"
        SettingRow {
            label: "Per-app volume, inputs and devices"
            last: true
            LinkButton { text: "Open Mixer…"; onClicked: Ui.launch("pavucontrol") }
        }
    }
}
