pragma Singleton
import QtQuick

QtObject {
    readonly property int panelWidth: 600
    readonly property int panelPadding: 14
    readonly property int searchBarHeight: 42
    readonly property int searchGap: 8

    readonly property int rowHeight: 42
    readonly property int rowInset: 4
    readonly property int rowRadius: 6
    readonly property int rowPadding: 12
    readonly property int rowSpacing: 12
    readonly property int listSpacing: 2
    readonly property int maxRows: 6

    readonly property int iconSize: 22
    readonly property int glyphSize: 24
    readonly property int labelSize: 17
    readonly property int transition: 120

    function listHeight(count) {
        const n = Math.min(count, maxRows)
        return n * rowHeight + Math.max(0, n - 1) * listSpacing
    }

    function panelHeight(count) {
        return panelPadding + searchBarHeight + searchGap + listHeight(count) + panelPadding
    }
}
