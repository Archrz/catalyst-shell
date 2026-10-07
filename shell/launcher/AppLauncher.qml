import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import QtCore
import Quickshell.Wayland
import Quickshell.Widgets
import "../theme"

PanelWindow {
    id: root

    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true
    exclusiveZone:  0

    WlrLayershell.layer:         WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    color:   "transparent"
    visible: animState !== "closed"

    mask: Region { item: panel }

    // State
    property string animState:     "closed"
    property int    selectedIndex: -1

    property bool wallpaperMode: false
    property bool clipboardMode: false
    property bool hiddenMode:    false
    readonly property bool appModeActive: !wallpaperMode && !clipboardMode
                                          && !hiddenMode

    property string wallpaperMediaFilter: "all"
    Settings {
        location: "file://" + Quickshell.env("HOME") + "/.config/catalyst/settings.conf"
        category: "Launcher"
        property alias wallpaperMediaFilter: root.wallpaperMediaFilter
    }

    property var filteredApps: []

    // Mode switching
    function _switchMode(wall, clip, hidden) {
        wallpaperMode = wall
        clipboardMode = clip
        hiddenMode    = hidden
    }

    function _pillText() {
        if (wallpaperMode) return "󰸉 Wallpaper"
        if (clipboardMode) return "󰅌 Clipboard"
        if (hiddenMode)    return " Hidden"
        return ""
    }

    function _placeholder() {
        if (wallpaperMode) return "Search wallpapers..."
        if (clipboardMode) return "Search clipboard..."
        if (hiddenMode)    return "Hidden apps..."
        return "Search..."
    }

    // Panel width
    readonly property int panelWidth: {
        if (wallpaperMode) return 900
        return LauncherMetrics.panelWidth
    }

    // App filter
    Timer {
        id: filterTimer
        interval: 10
        onTriggered: _updateFilter()
    }

    function _updateFilter() {
        var firstMatch = -1
        var items = []
        var q = searchBar.text.toLowerCase()

        for (var i = 0; i < appView.appsRepeaterCount; i++) {
            var item = appView.appItemAt(i)
            if (!item) continue

            var hidden    = LauncherHiddenApps.isHidden(item.appId)
            var nameMatch = q === "" ||
                item.appName.toLowerCase().includes(q) ||
                (item.appData && item.appData.genericName && String(item.appData.genericName).toLowerCase().includes(q)) ||
                (item.appData && item.appData.comment    && String(item.appData.comment).toLowerCase().includes(q))    ||
                (item.appData && item.appData.keywords   && String(item.appData.keywords).toLowerCase().includes(q))

            var isMatch = !hidden && nameMatch
            item.isMatch = isMatch

            if (isMatch) {
                items.push({ item: item, origIndex: i,
                             usage: AppUsageTracker.getUsage(item.appId),
                             name:  item.appName.toLowerCase() })
            } else {
                item.filteredIndex = -1
            }
        }

        items.sort(function(a, b) {
            if (b.usage !== a.usage) return b.usage - a.usage
            return a.name.localeCompare(b.name)
        })

        var mapped = []
        for (var j = 0; j < items.length; j++) {
            items[j].item.filteredIndex = j
            mapped.push(items[j].origIndex)
            if (firstMatch === -1) firstMatch = items[j].origIndex
        }

        root.filteredApps    = mapped
        appView.filteredApps = mapped

        root.selectedIndex    = firstMatch
        appView.selectedIndex = firstMatch
    }

    // Connections
    Connections {
        target: LauncherState
        function onVisibleChanged() {
            root.animState = LauncherState.visible ? "open" : "closing"
            if (LauncherState.visible) {
                appView.closeHiddenMenu()
                if (root.appModeActive) filterTimer.restart()
            } else {
                appView.closeHiddenMenu()
            }
        }
    }
    Connections {
        target: LauncherHiddenApps
        function onHiddenAppsChanged() { if (root.appModeActive) filterTimer.restart() }
    }
    Connections {
        target: AppUsageTracker
        function onUsageMapChanged()   { if (root.appModeActive) filterTimer.restart() }
    }

    onAnimStateChanged: {
        if (animState === "open")   searchBar.forceActiveFocus()
        if (animState === "closed") root._switchMode(false, false, false)
    }

    // IPC
    IpcHandler {
        target: "launcher"

        function toggle(): void {
            if (!LauncherState.visible) {
                root._switchMode(false, false, false)
                searchBar.clear()
            }
            LauncherState.toggle()
        }

        function openWallpaper(): void {
            root._switchMode(true, false, false)
            searchBar.clear()
            LauncherState.show()
            wallpaperView.load()
            searchBar.forceActiveFocus()
        }

        function openClipboard(): void {
            root._switchMode(false, true, false)
            searchBar.clear()
            LauncherState.show()
            clipboardView.load()
            searchBar.forceActiveFocus()
        }

    }

    // Panel
    Rectangle {
        id: panel

        width:  root.panelWidth
        height: panelColumn.implicitHeight + 28

        x: Math.round((parent.width  - width)  / 2)
        y: Math.round((parent.height - height) / 2)

        radius:       12
        color:        PanelColors.popupBackground
        Behavior on color { ColorAnimation { duration: PanelColors.transitionDuration } }
        border.color: PanelColors.rowBackground
        Behavior on border.color { ColorAnimation { duration: PanelColors.transitionDuration } }
        border.width: 4

        opacity:   0.0
        transform: Translate { id: panelSlide; y: 28 }

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    searchBar.forceActiveFocus()
            }
        }

        states: [
            State {
                name: "open";    when: root.animState === "open"
                PropertyChanges { target: panel;      opacity: 1.0 }
                PropertyChanges { target: panelSlide; y: 0         }
            },
            State {
                name: "closing"; when: root.animState === "closing"
                PropertyChanges { target: panel;      opacity: 0.0 }
                PropertyChanges { target: panelSlide; y: 28        }
            }
        ]

        transitions: [
            Transition {
                to: "open"
                SequentialAnimation {
                    PropertyAction  { target: panel;      property: "width"   }
                    PropertyAction  { target: panel;      property: "height"  }
                    PropertyAction  { target: panelSlide; property: "y";       value: 28  }
                    PropertyAction  { target: panel;      property: "opacity"; value: 0.0 }
                    ParallelAnimation {
                        NumberAnimation { target: panelSlide; property: "y";       to: 0;   duration: 280; easing.type: Easing.OutExpo  }
                        NumberAnimation { target: panel;      property: "opacity"; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
                    }
                }
            },
            Transition {
                to: "closing"
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { target: panelSlide; property: "y";       to: 28;  duration: 180; easing.type: Easing.InCubic }
                        NumberAnimation { target: panel;      property: "opacity"; to: 0.0; duration: 150; easing.type: Easing.InCubic }
                    }
                    ScriptAction { script: root.animState = "closed" }
                }
            }
        ]

        Column {
            id: panelColumn
            anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 14; leftMargin: 10; rightMargin: 10; bottomMargin: 10 }
            spacing: LauncherMetrics.searchGap

            // Search bar
            LauncherSearchBar {
                id: searchBar
                width: parent.width
                anchors.left:        parent.left
                anchors.right:       parent.right
                anchors.leftMargin:  4
                anchors.rightMargin: 4

                pillText:    root._pillText()
                placeholder: root._placeholder()

                rightPillText: {
                    if (root.clipboardMode) return "󰩺"
                    if (root.wallpaperMode) {
                        if (root.wallpaperMediaFilter === "all")   return " ALL"
                        if (root.wallpaperMediaFilter === "image") return " IMG"
                        return " VID"
                    }
                    return ""
                }
                rightPillDestructive: root.clipboardMode
                rightPillDisabled:    root.clipboardMode && clipboardView.filteredClipboard.length === 0
                rightPillTooltip: {
                    if (root.clipboardMode) return "Clear all clipboard history"
                    if (root.wallpaperMode) return "Filter: ALL → IMG → VID"
                    return ""
                }

                onRightPillClicked: {
                    if (root.clipboardMode) {
                        clipboardView.showDeleteAllConfirm()
                    } else if (root.wallpaperMode) {
                        if (root.wallpaperMediaFilter === "all")        root.wallpaperMediaFilter = "image"
                        else if (root.wallpaperMediaFilter === "image") root.wallpaperMediaFilter = "video"
                        else                                            root.wallpaperMediaFilter = "all"
                    }
                }

                onTextChanged: {
                    var t = searchBar.text
                    if (root.appModeActive) {
                        if (t === "/w") {
                            root._switchMode(true, false, false)
                            searchBar.clear()
                            wallpaperView.load()
                            return
                        }
                        if (t === "/c") {
                            root._switchMode(false, true, false)
                            searchBar.clear()
                            clipboardView.load()
                            return
                        }
                        if (t === "/h") {
                            root._switchMode(false, false, true)
                            searchBar.clear()
                            return
                        }
                    }
                    if (root.wallpaperMode)      wallpaperView.setFilter(t)
                    else if (root.clipboardMode) clipboardView.setFilter(t)
                    else if (!root.hiddenMode)   filterTimer.restart()
                }

                onUpPressed: {
                    if      (root.wallpaperMode) wallpaperView.navigateUp()
                    else if (root.clipboardMode) clipboardView.navigateUp()
                    else if (root.hiddenMode)    hiddenAppsView.navigateUp()
                    else                         appView.navigateGrid(0, -1)
                }
                onDownPressed: {
                    if      (root.wallpaperMode) wallpaperView.navigateDown()
                    else if (root.clipboardMode) clipboardView.navigateDown()
                    else if (root.hiddenMode)    hiddenAppsView.navigateDown()
                    else                         appView.navigateGrid(0, +1)
                }
                onLeftPressed: {
                    if      (root.wallpaperMode) wallpaperView.navigateLeft()
                }
                onRightPressed: {
                    if      (root.wallpaperMode) wallpaperView.navigateRight()
                }
                onTabPressed: {
                    if      (root.wallpaperMode) wallpaperView.navigateTab()
                    else if (root.clipboardMode) clipboardView.navigateTab()
                    else if (root.hiddenMode)    hiddenAppsView.navigateTab()
                    else                         appView.navigateGrid(+1, 0)
                }
                onBacktabPressed: {
                    if      (root.wallpaperMode) wallpaperView.navigateBacktab()
                    else if (root.clipboardMode) clipboardView.navigateBacktab()
                    else if (root.hiddenMode)    hiddenAppsView.navigateBacktab()
                    else                         appView.navigateGrid(-1, 0)
                }
                onDeletePressed: {
                    if (root.clipboardMode) clipboardView.deleteSelected()
                }
                onReturnPressed: {
                    if      (root.wallpaperMode) wallpaperView.confirm()
                    else if (root.clipboardMode) clipboardView.confirm()
                    else if (root.hiddenMode)    hiddenAppsView.confirm()
                    else {
                        if (appView.selectedIndex !== -1) {
                            var item = appView.appItemAt(appView.selectedIndex)
                            if (item) item.executeApp()
                        } else if (searchBar.text.trim() !== "") {
                            Quickshell.execDetached(["bash", "-c", searchBar.text])
                            LauncherState.hide()
                        }
                    }
                }
                onEscapePressed: {
                    if (!root.appModeActive)
                        LauncherState.hide()
                    else if (appView._hiddenMenuOpen)
                        appView.closeHiddenMenu()
                    else
                        LauncherState.hide()
                }
            }

            // Clipboard view
            LauncherClipboardView {
                id:    clipboardView
                width: parent.width

                height:  root.clipboardMode ? 360 : 0
                clip:    true
                visible: height > 0
                opacity: root.clipboardMode ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                onDismissed: { LauncherState.hide(); searchBar.clear() }
            }

            // Wallpaper view
            LauncherWallpaperView {
                id:    wallpaperView
                width: parent.width

                mediaFilter: root.wallpaperMediaFilter

                height:  root.wallpaperMode ? 660 : 0
                clip:    true
                visible: height > 0
                opacity: root.wallpaperMode ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                onDismissed: { LauncherState.hide(); searchBar.clear(); filterTimer.restart() }
            }

            // Hidden apps view
            Item {
                id:    hiddenAppsView
                width: parent.width

                height:  root.hiddenMode ? 262 : 0
                clip:    true
                visible: height > 0
                opacity: root.hiddenMode ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                property int selectedIndex: 0

                onVisibleChanged: {
                    if (visible) selectedIndex = 0
                }

                function navigateUp()      { _move(0, -1) }
                function navigateDown()    { _move(0, +1) }
                function navigateTab()     { _move(+1, 0) }
                function navigateBacktab() { _move(-1, 0) }

                function _move(colDelta, rowDelta) {
                    var count = LauncherHiddenApps.hiddenApps.length
                    if (count === 0) return

                    var next = Math.max(0, Math.min(selectedIndex + colDelta + rowDelta, count - 1))

                    selectedIndex = next

                    if (hiddenAppsLoader.item) {
                        hiddenAppsLoader.item.positionViewAtIndex(next, ListView.Contain)
                    }
                }

                function confirm() {
                    if (selectedIndex >= 0 && selectedIndex < LauncherHiddenApps.hiddenApps.length) {
                        var app = LauncherHiddenApps.hiddenApps[selectedIndex]
                        LauncherHiddenApps.show(app.id) // This unhides the app
                        filterTimer.restart()
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text:             "No hidden apps"
                    font.pixelSize:   14
                    font.bold:        true
                    font.family:      PanelColors.monoFont
                    color:            PanelColors.textDim
                    visible:          LauncherHiddenApps.hiddenApps.length === 0
                }

                Loader {
                    id: hiddenAppsLoader
                    anchors.fill: parent
                    sourceComponent: hiddenListComp
                }

                Component {
                    id: hiddenListComp
                    ListView {
                        anchors.fill: parent
                        clip: true; spacing: 2
                        model: LauncherHiddenApps.hiddenApps
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        delegate: Item {
                            id: hiddenDelegate
                            required property var modelData
                            required property int index
                            width: ListView.view.width; height: 44
                            Rectangle {
                                anchors { fill: parent; leftMargin: 4; rightMargin: 4 }
                                radius: 6
                                color: hiddenRowHover.containsMouse || hiddenAppsView.selectedIndex === index
                                       ? PanelColors.rowBackground : "transparent"
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Row {
                                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                    spacing: 12
                                    IconImage {
                                        anchors.verticalCenter: parent.verticalCenter
                                        implicitSize: 22
                                        source: Quickshell.iconPath(modelData.icon)
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.name
                                        font.pixelSize: 16; font.bold: true
                                        font.family: PanelColors.monoFont
                                        color: PanelColors.textMain
                                        width: hiddenAppsView.width - 14 - 22 - 12 - 12 - 8
                                        elide: Text.ElideRight
                                    }
                                }
                                MouseArea {
                                    id: hiddenRowHover
                                    anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onEntered: hiddenAppsView.selectedIndex = index
                                    onClicked: {
                                        LauncherHiddenApps.show(modelData.id)
                                        filterTimer.restart()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // App view
            LauncherAppView {
                id:           appView
                width:        parent.width
                searchText:   searchBar.text

                readonly property int activeHeight: (function() {
                    var n = Math.max(root.filteredApps.length, searchBar.text.trim() !== "" ? 1 : 0)
                    return LauncherMetrics.listHeight(n)
                }())
                height: root.appModeActive ? activeHeight : 0
                Behavior on height {
                    enabled: root.appModeActive
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                clip:    true
                opacity: root.appModeActive ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                visible: opacity > 0

                filteredApps:  root.filteredApps
                selectedIndex: root.selectedIndex

                onFilterRequested:      filterTimer.restart()
                onSelectedIndexChanged: (idx) => { if (idx !== undefined) root.selectedIndex = idx }
            }
        }

        Keys.onEscapePressed: {
            if (appView._hiddenMenuOpen) appView.closeHiddenMenu()
            else LauncherState.hide()
        }
        focus: true
    }
}
