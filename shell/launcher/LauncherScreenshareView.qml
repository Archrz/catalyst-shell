import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"

Item {
    id: root

    property string searchText: ""
    property var tiles: []
    property int windowCount: 0
    property int selectedIndex: 0

    signal picked(var tile)

    readonly property var filteredTiles: {
        const q = root.searchText.toLowerCase().trim()
        if (q === "") return root.tiles
        return root.tiles.filter(t => t.label.toLowerCase().includes(q))
    }

    function load(text) {
        const lines = text.split("\n").filter(l => l.trim().length > 0)
        const built = []
        let windows = 0

        for (const line of lines) {
            if (line.startsWith("Monitor: ")) {
                const name = line.substring("Monitor: ".length).split(" ")[0]
                built.push({ raw: line, key: line, label: "Fullscreen: " + name, kind: "monitor" })
            } else if (line.startsWith("Window: ")) {
                const rest = line.substring("Window: ".length)
                const m = rest.match(/^(.*) \(([^)]*)\)$/)
                built.push({ raw: line, key: m ? m[2] : line, label: m ? m[1] : rest,
                             kind: "window", windowIndex: windows++ })
            }
        }

        root.windowCount = windows
        root.tiles = built
        root.selectedIndex = 0
    }

    function entryFor(tile) {
        if (tile.kind !== "window") return null
        const tls = ToplevelManager.toplevels.values
        // title first: immune to the window set shifting under a stale list.
        // duplicate titles are fine here, they resolve to the same app anyway.
        let tl = tls.find(t => t.title === tile.label)
        if (!tl && tls.length === root.windowCount) tl = tls[tile.windowIndex]
        if (!tl || DesktopEntries.applications.values.length === 0) return null
        return DesktopEntries.byId(tl.appId)
    }

    function tileForKey(key) {
        if (key === "") return null
        return root.tiles.find(t => t.key === key) ?? null
    }

    function setFilter(t) { root.searchText = t; root.selectedIndex = 0 }
    function navigateUp()   { if (root.selectedIndex > 0) root.selectedIndex-- }
    function navigateDown() { if (root.selectedIndex < root.filteredTiles.length - 1) root.selectedIndex++ }
    function confirm() {
        const t = root.filteredTiles[root.selectedIndex]
        if (t) root.picked(t)
    }

    ListView {
        id: listView
        anchors.fill: parent
        clip: true
        spacing: LauncherMetrics.listSpacing

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        model: root.filteredTiles
        currentIndex: root.selectedIndex

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property var entry: root.entryFor(row.modelData)

            width: listView.width
            height: LauncherMetrics.rowHeight

            LauncherRow {
                highlighted: row.index === root.selectedIndex
                iconSource: row.entry ? Quickshell.iconPath(row.entry.icon, true) : ""
                glyph: row.modelData.kind === "monitor" ? "" : ""
                label: row.modelData.label

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selectedIndex = row.index
                    onClicked: root.picked(row.modelData)
                }
            }
        }
    }
}
