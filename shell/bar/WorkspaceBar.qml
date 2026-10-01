import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

Row {
    id: root
    spacing: 4

    property var tagFocused: [false, false, false, false, false, false, false, false, false]
    property var tagClients: [0, 0, 0, 0, 0, 0, 0, 0, 0]
    property int focusedTag: 1
    property bool canScroll: true

    function parseLine(line) {
        const trimmed = line.trim()
        if (trimmed.length === 0) return
        try {
            const json = JSON.parse(trimmed)
            const monitors = json["all_tags"]
            if (!monitors || monitors.length === 0) return
            const tags = monitors[0]["tags"]
            if (!tags) return

            const f = [false, false, false, false, false, false, false, false, false]
            const c = [0, 0, 0, 0, 0, 0, 0, 0, 0]
            let focused = 1

            for (let i = 0; i < tags.length; i++) {
                const tag = tags[i]
                const idx = tag["index"] - 1
                if (idx < 0 || idx >= 9) continue
                f[idx] = tag["is_active"] === true
                c[idx] = tag["client_count"] || 0
                if (f[idx]) focused = tag["index"]
            }

            root.tagFocused = f
            root.tagClients = c
            root.focusedTag = focused
        } catch (e) {
            console.warn("WorkspaceBar parse error:", e, trimmed)
        }
    }

    Process {
        id: initProc
        command: ["mmsg", "get", "all-tags"]
        running: true
        stdout: SplitParser {
            onRead: (line) => root.parseLine(line)
        }
    }

    Process {
        id: watchProc
        command: ["mmsg", "watch", "all-tags"]
        running: true
        onRunningChanged: if (!running) watchRestartTimer.start()
        stdout: SplitParser {
            onRead: (line) => root.parseLine(line)
        }
    }

    Timer {
        id: watchRestartTimer
        interval: 1000
        onTriggered: watchProc.running = true
    }

    Timer {
        id: scrollThrottle
        interval: 30
        onTriggered: root.canScroll = true
    }

    Repeater {
        model: 9
        delegate: Rectangle {
            id: pill

            required property int modelData

            readonly property int tagNum: modelData + 1
            readonly property bool isFocused: root.tagFocused[modelData]
            readonly property bool hasClients: root.tagClients[modelData] > 0
            readonly property bool shouldShow: isFocused || hasClients
            property bool hovered: false

            visible: width > 0
            width: shouldShow ? 20 : 0
            Behavior on width {
                SmoothedAnimation { velocity: 120; easing.type: Easing.OutExpo }
            }

            height: 20
            radius: 4

            color: {
                if (isFocused) return hovered
                    ? Qt.lighter(PanelColors.workspaceActive, 1.15)
                    : PanelColors.workspaceActive
                return hovered
                    ? Qt.lighter(PanelColors.workspaceInactive, 1.4)
                    : PanelColors.workspaceInactive
            }
            Behavior on color { ColorAnimation { duration: 150 } }

            clip: true

            Text {
                anchors.centerIn: parent
                text: pill.tagNum
                color: pill.isFocused ? PanelColors.pillForeground : PanelColors.textDim
                font.pixelSize: 12
                font.bold: true
                font.family: PanelColors.monoFont
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: pill.hovered = true
                onExited: pill.hovered = false

                onClicked: {
                    Quickshell.execDetached(["mmsg", "dispatch", "view," + pill.tagNum])
                }

                onWheel: (event) => {
                    if (!root.canScroll) return
                    const visible = []
                    for (let i = 0; i < 9; i++) {
                        if (root.tagFocused[i] || root.tagClients[i] > 0)
                            visible.push(i + 1)
                    }
                    if (visible.length === 0) return
                    let idx = visible.indexOf(root.focusedTag)
                    if (idx === -1) idx = 0
                    idx = event.angleDelta.y < 0
                        ? Math.min(idx + 1, visible.length - 1)
                        : Math.max(idx - 1, 0)
                    Quickshell.execDetached(["mmsg", "dispatch", "view," + visible[idx]])
                    root.canScroll = false
                    scrollThrottle.start()
                }
            }
        }
    }
}
