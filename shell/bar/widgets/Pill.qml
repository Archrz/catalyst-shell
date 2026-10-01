import QtQuick
import "../../theme"

Rectangle {
    id: root
    property color pillColor: PanelColors.audio
    property color textColor: PanelColors.pillForeground
    property string label: ""
    property string widestLabel: ""
    property int minWidth: 0
    property alias mouseArea: mouseArea
    default property alias content: contentRow.data

    property bool hoverReveal: false
    property bool forceReveal: false

    property bool _delayedForceReveal: forceReveal
    Timer {
        id: forceRevealTimer
        interval: 250
        running: !root.forceReveal && root._delayedForceReveal
        onTriggered: root._delayedForceReveal = false
    }
    onForceRevealChanged: if (forceReveal) root._delayedForceReveal = true

    property bool isHovered: mouseArea.containsMouse
    property bool _delayedHover: isHovered
    Timer {
        id: hoverTimer
        interval: 250
        running: !root.isHovered && root._delayedHover
        onTriggered: root._delayedHover = false
    }
    onIsHoveredChanged: if (isHovered) root._delayedHover = true

    readonly property bool isRevealed: !hoverReveal || forceReveal || _delayedForceReveal || isHovered || _delayedHover

    property string labelIcon: {
        if (label === "") return ""
        let idx = label.indexOf(" ")
        return idx !== -1 ? label.substring(0, idx) : label
    }

    property string labelInfo: {
        if (label === "") return ""
        let idx = label.indexOf(" ")
        return idx !== -1 ? label.substring(idx + 1) : ""
    }

    TextMetrics {
        id: widestMetric
        font.pixelSize: 12
        font.bold: true
        font.family: PanelColors.monoFont
        text: root.widestLabel
    }

    property int effectiveMinWidth: {
        if (hoverReveal && !isRevealed) return minWidth
        return Math.max(minWidth, widestLabel !== "" ? widestMetric.width + 10 : 0)
    }

    implicitHeight: 20
    property real targetWidth: Math.max(effectiveMinWidth, contentRow.implicitWidth + 10)
    property bool isGrowing: targetWidth > width
    implicitWidth: targetWidth

    Behavior on targetWidth {
        NumberAnimation {
            duration: root.isGrowing ? 250 : 200
            easing.type: Easing.OutExpo
        }
    }

    radius: 4
    color: mouseArea.containsMouse ? Qt.lighter(pillColor, 1.15) : pillColor
    scale: mouseArea.containsMouse ? 1.03 : 1.0
    clip: true

    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 3

        Text {
            id: iconLabel
            visible: root.labelIcon !== ""
            text: root.labelIcon
            font.pixelSize: 12
            font.bold: true
            font.family: PanelColors.monoFont
            color: root.textColor
        }

        Text {
            id: infoLabel
            visible: root.labelInfo !== "" && (!root.hoverReveal || root.isRevealed)
            text: root.labelInfo
            font.pixelSize: 12
            font.bold: true
            font.family: PanelColors.monoFont
            color: root.textColor
            opacity: (!root.hoverReveal || root.isRevealed) ? 1 : 0
        }
    }
}
