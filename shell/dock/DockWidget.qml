import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "."
import "../theme"

PanelWindow {
    id: dock

    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayershell.Top
    color: "transparent"

    readonly property int margin:     8
    readonly property int pillHeight: 64
    readonly property int fullHeight: pillHeight + margin * 2
    implicitHeight: fullHeight

    mask: Region {
        item: dockVisible ? pill : triggerStrip
    }

    // State
    property bool hovering:    false
    property bool anyMenuOpen: false

    readonly property bool dockVisible: !windowsPresent || hovering || anyMenuOpen

    // Workspace tracking
    property int    focusedWorkspaceId: -1
    property var    windowWorkspaceMap: ({})

    readonly property bool windowsPresent: {
        const id = dock.focusedWorkspaceId
        if (id < 0) return false
        const map = dock.windowWorkspaceMap
        for (const wid in map) {
            if (map[wid] === id) return true
        }
        return false
    }

    Socket {
        id: niriSocket

        readonly property string socketPath: Quickshell.env("NIRI_SOCKET")

        path: socketPath
        connected: socketPath !== ""

        onConnectedChanged: {
            if (connected) {
                niriSocket.write('"EventStream"\n')
            } else {
                reconnectTimer.start()
            }
        }

        parser: SplitParser {
            onRead: (line) => {
                const trimmed = line.trim()
                if (trimmed.length === 0) return
                try {
                    dock.handleNiriEvent(JSON.parse(trimmed))
                } catch (e) {
                    console.warn("DockWidget: JSON parse error:", e, "raw:", trimmed)
                }
            }
        }
    }

    Timer {
        id: reconnectTimer
        interval: 1000
        onTriggered: niriSocket.connected = niriSocket.socketPath !== ""
    }

    function handleNiriEvent(ev) {
        if (ev["WorkspacesChanged"] !== undefined) {
            const ws = ev["WorkspacesChanged"]["workspaces"]
            for (let i = 0; i < ws.length; i++) {
                if (ws[i]["is_focused"]) {
                    dock.focusedWorkspaceId = ws[i]["id"]
                    break
                }
            }

        } else if (ev["WorkspaceActivated"] !== undefined) {
            const data = ev["WorkspaceActivated"]
            if (data["focused"]) {
                dock.focusedWorkspaceId = data["id"]
            }

        } else if (ev["WindowsChanged"] !== undefined) {
            const wins = ev["WindowsChanged"]["windows"]
            const map = {}
            for (let i = 0; i < wins.length; i++) {
                const w = wins[i]
                if (w["workspace_id"] !== undefined) {
                    map[w["id"]] = w["workspace_id"]
                }
            }
            dock.windowWorkspaceMap = map

        } else if (ev["WindowOpenedOrChanged"] !== undefined) {
            const w = ev["WindowOpenedOrChanged"]["window"]
            if (w["workspace_id"] !== undefined) {
                const map = Object.assign({}, dock.windowWorkspaceMap)
                map[w["id"]] = w["workspace_id"]
                dock.windowWorkspaceMap = map
            }

        } else if (ev["WindowClosed"] !== undefined) {
            const id = ev["WindowClosed"]["id"]
            const map = Object.assign({}, dock.windowWorkspaceMap)
            delete map[id]
            dock.windowWorkspaceMap = map
        }
    }

    // Hide debounce
    Timer {
        id: hideTimer
        interval: 300
        onTriggered: dock.hovering = false
    }

    // Trigger strip
    Item {
        id: triggerStrip
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        height: 4

        HoverHandler {
            onHoveredChanged: {
                if (hovered) { hideTimer.stop(); dock.hovering = true }
                else hideTimer.restart()
            }
        }
    }

    // Pill
    Item {
        id: pill

        x: (parent.width - width) / 2
        width:  row.implicitWidth + dock.margin * 2
        height: dock.pillHeight

        readonly property real restingY: parent.height - dock.pillHeight - dock.margin
        readonly property real hiddenY:  parent.height + dock.margin
        y: dock.dockVisible ? restingY : hiddenY

        Behavior on y {
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }

        opacity: dock.dockVisible ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.fill: parent
            color:        PanelColors.barBackground
            Behavior on color { ColorAnimation { duration: PanelColors.transitionDuration } }
            radius:       10
            border.color: PanelColors.border
            Behavior on border.color { ColorAnimation { duration: PanelColors.transitionDuration } }
            border.width: 3
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: PinnedApps.apps
                AppIcon {
                    appId:    modelData.id
                    appLabel: modelData.label
                    iconName: modelData.icon
                    steamId:  modelData.steamId  ?? ""
                    execName: modelData.execName ?? ""
                }
            }
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered) { hideTimer.stop(); dock.hovering = true }
                else hideTimer.restart()
            }
        }
    }
}
