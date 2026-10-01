//@ pragma IconTheme Papirus-Dark
import QtQuick
import Quickshell
import Quickshell.Io as Io
import Quickshell.Wayland
import "theme"
import "launcher"

ShellRoot {
    id: appRoot
    readonly property string cachePath: "/tmp/qs-screenshare-cache"
    readonly property int cacheWindowMs: 5000
    readonly property int cacheMaxUses: 2

    property bool sourcesReady: false

    function finish(raw) {
        dataFile.setText(raw)
        Qt.quit()
    }

    function pick(tile) {
        cacheFile.setText(Date.now() + "\n0\n" + tile.key)
        appRoot.finish(tile.raw)
    }

    function showPicker() {
        picker.visible = true
        searchBar.forceActiveFocus()
    }

    Io.FileView {
        id: dataFile
        path: "file://" + Quickshell.env("A")
        atomicWrites: false
        printErrors: false
        onLoaded: {
            view.load(text())
            appRoot.sourcesReady = true
            cacheFile.reload()
        }
    }

    Io.FileView {
        id: cacheFile
        path: "file://" + appRoot.cachePath
        atomicWrites: false
        printErrors: false
        onLoaded: {
            if (!appRoot.sourcesReady) return

            const parts = text().split("\n")
            const ts = parseInt(parts[0], 10)
            const uses = parseInt(parts[1], 10)
            const tile = view.tileForKey(parts.slice(2).join("\n"))
            const fresh = !isNaN(ts) && (Date.now() - ts) < appRoot.cacheWindowMs
            const spare = !isNaN(uses) && uses < appRoot.cacheMaxUses

            if (tile && fresh && spare) {
                cacheFile.setText(ts + "\n" + (uses + 1) + "\n" + tile.key)
                appRoot.finish(tile.raw)
            } else {
                appRoot.showPicker()
            }
        }
        onLoadFailed: { if (appRoot.sourcesReady) appRoot.showPicker() }
    }

    PanelWindow {
        id: picker
        visible: false
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }

        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "qs-screenshare-picker"
        exclusiveZone: 0

        Rectangle {
            id: panel
            anchors.centerIn: parent
            width: LauncherMetrics.panelWidth
            height: LauncherMetrics.panelHeight(view.filteredTiles.length)
            radius: 12
            color: PanelColors.popupBackground
            border.color: PanelColors.rowBackground
            border.width: 4

            LauncherSearchBar {
                id: searchBar
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: LauncherMetrics.panelPadding
                }
                pillText: "󰄙"
                placeholder: "Search..."
                onTextChanged: view.setFilter(text)
                onEscapePressed: appRoot.finish("")
                onUpPressed: view.navigateUp()
                onDownPressed: view.navigateDown()
                onReturnPressed: view.confirm()
            }

            LauncherScreenshareView {
                id: view
                anchors {
                    top: searchBar.bottom
                    left: parent.left
                    right: parent.right
                    topMargin: LauncherMetrics.searchGap
                    leftMargin: LauncherMetrics.panelPadding - LauncherMetrics.rowInset
                    rightMargin: LauncherMetrics.panelPadding - LauncherMetrics.rowInset
                }
                height: LauncherMetrics.listHeight(view.filteredTiles.length)
                onPicked: tile => appRoot.pick(tile)
            }
        }
    }
}
