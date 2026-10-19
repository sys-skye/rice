import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.common

// ⌘/ — searchable cheat sheet built from ~/.config/hypr/bindings.conf
// (sections come from the "# ── Name ──" comment lines in that file).
PanelWindow {
    id: root
    screen: Quickshell.screens[0]
    visible: Ui.openPanel === "keybinds"
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "cheatsheet"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property var sections: []      // [{ name, binds: [{ keys, desc }] }]
    readonly property string query: search.text.toLowerCase()
    readonly property var shown: sections
        .map(s => ({ name: s.name, binds: s.binds.filter(b => !query || (b.desc + " " + b.keys).toLowerCase().includes(query)) }))
        .filter(s => s.binds.length > 0)
    // Balance sections over two columns by row count
    readonly property var columns: {
        const total = shown.reduce((n, s) => n + s.binds.length + 2, 0)
        const left = [], right = []
        let n = 0
        for (const s of shown) { (n < total / 2 ? left : right).push(s); n += s.binds.length + 2 }
        return [left, right]
    }

    onVisibleChanged: if (visible) { search.text = ""; search.forceActiveFocus(); reader.running = true; card.opacity = 0; card.scale = 0.97; showAnim.restart() }

    readonly property var modSymbols: ({ CTRL: "⌃", ALT: "⌥", SHIFT: "⇧", SUPER: "⌘" })
    readonly property var keyNames: ({
        SPACE: "Space", RETURN: "Return", ESCAPE: "Esc", SLASH: "/", TAB: "Tab", PRINT: "Print",
        LEFT: "←", RIGHT: "→", UP: "↑", DOWN: "↓",
        "mouse:272": "Drag", "mouse:273": "Right-drag", mouse_down: "Scroll ↓", mouse_up: "Scroll ↑"
    })
    function prettyKeys(mods, key) {
        const m = ["CTRL", "ALT", "SHIFT", "SUPER"].filter(x => mods.toUpperCase().split(/\s+/).includes(x)).map(x => modSymbols[x]).join("")
        let k = key.trim()
        const code = k.match(/^code:(1[0-9])$/)
        if (code) k = String((Number(code[1]) - 9) % 10)
        else k = keyNames[k] ?? keyNames[k.toUpperCase()] ?? (k.length === 1 ? k.toUpperCase() : k)
        return m + (m ? " " : "") + k
    }
    function parse(text) {
        const out = []
        let cur = null
        for (const line of text.split("\n")) {
            const head = line.match(/^#\s*──\s*(.+?)\s*[─(]/)
            if (head) { cur = { name: head[1], binds: [] }; out.push(cur); continue }
            if (/^#\s*Also:.*swipe/i.test(line) && cur) cur.binds.push({ keys: "3-finger swipe", desc: "Switch space" })
            const b = line.match(/^bind\w*\s*=\s*([^,]*),\s*([^,]+),\s*([^,]*),/)
            if (!b || !b[3].trim() || /^XF86/.test(b[2].trim())) continue
            if (!cur) { cur = { name: "General", binds: [] }; out.push(cur) }
            cur.binds.push({ keys: prettyKeys(b[1], b[2]), desc: b[3].trim() })
        }
        return out.filter(s => s.binds.length > 0)
    }

    Process {
        id: reader
        command: ["cat", Quickshell.env("HOME") + "/.config/hypr/bindings.conf"]
        stdout: StdioCollector { onStreamFinished: root.sections = root.parse(text) }
    }

    // Dim the desktop; click outside the card to close
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        MouseArea { anchors.fill: parent; onClicked: Ui.openPanel = "" }
    }

    component Section: Column {
        property var section
        width: parent.width
        spacing: 2
        Label { text: section.name; bold: true; dim: true; font.pixelSize: Theme.smallFontSize; height: 24; leftPadding: 4 }
        Repeater {
            model: section.binds
            delegate: Item {
                required property var modelData
                width: parent.width
                height: 26
                Rectangle {
                    id: pill
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(64, keyLabel.implicitWidth + 14)
                    height: 22
                    radius: 6
                    color: Theme.fg(0.10)
                    border.color: Theme.fg(0.08)
                    Label { id: keyLabel; anchors.centerIn: parent; text: modelData.keys; font.pixelSize: 12 }
                }
                Label {
                    anchors.left: pill.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.desc
                }
            }
        }
        Item { width: 1; height: 10 }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(860, parent.width - 80)
        height: Math.min(header.height + body.implicitHeight + 40, parent.height - 120)
        radius: 18
        color: Theme.panelSolid
        border.color: Theme.panelBorder
        MouseArea { anchors.fill: parent }   // don't close when clicking the card

        ParallelAnimation {
            id: showAnim
            NumberAnimation { target: card; property: "opacity"; to: 1; duration: 140; easing.type: Easing.OutCubic }
            NumberAnimation { target: card; property: "scale"; to: 1; duration: 180; easing.type: Easing.OutCubic }
        }

        Item {
            id: header
            x: 20; y: 16
            width: parent.width - 40
            height: 44
            Label { anchors.verticalCenter: parent.verticalCenter; text: "Keyboard Shortcuts"; bold: true; font.pixelSize: 17 }
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 240; height: 30; radius: 8
                color: Theme.fg(0.08)
                border.color: search.activeFocus ? Theme.accent : Theme.panelBorder
                Icon { x: 9; anchors.verticalCenter: parent.verticalCenter; text: String.fromCodePoint(0xF0349); size: 14; color: Theme.textDim }
                TextInput {
                    id: search
                    anchors.fill: parent
                    anchors.leftMargin: 30
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    Label { anchors.verticalCenter: parent.verticalCenter; text: "Search"; dim: true; visible: !search.text }
                    Keys.onEscapePressed: search.text ? search.text = "" : Ui.openPanel = ""
                }
            }
        }
        Rectangle { x: 20; y: header.y + header.height + 6; width: parent.width - 40; height: 1; color: Theme.separator }

        SmoothFlickable {
            id: flick
            x: 20
            y: header.y + header.height + 16
            width: parent.width - 40
            height: parent.height - y - 14
            contentHeight: body.implicitHeight

            Row {
                id: body
                width: flick.width
                spacing: 28
                Repeater {
                    model: root.columns
                    delegate: Column {
                        required property var modelData
                        width: (body.width - body.spacing) / 2
                        Repeater {
                            model: modelData
                            delegate: Section { required property var modelData; section: modelData }
                        }
                    }
                }
            }
        }
        Label {
            anchors.centerIn: flick
            visible: root.shown.length === 0 && root.sections.length > 0
            text: "No shortcuts match “" + search.text + "”"
            dim: true
        }
    }
}
