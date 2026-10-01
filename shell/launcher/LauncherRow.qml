import QtQuick
import Quickshell.Widgets
import "../theme"

Rectangle {
    id: root

    property string iconSource: ""
    property string glyph: ""
    property string label: ""
    property bool highlighted: false
    property bool subdued: false

    default property alias content: overlay.data

    anchors {
        fill: parent
        leftMargin: LauncherMetrics.rowInset
        rightMargin: LauncherMetrics.rowInset
    }
    radius: LauncherMetrics.rowRadius
    color: root.highlighted ? PanelColors.launcher
         : root.subdued    ? PanelColors.rowBackground
                           : "transparent"
    Behavior on color { ColorAnimation { duration: LauncherMetrics.transition } }

    Row {
        anchors {
            fill: parent
            leftMargin: LauncherMetrics.rowPadding
            rightMargin: LauncherMetrics.rowPadding
        }
        spacing: LauncherMetrics.rowSpacing

        IconImage {
            visible: root.glyph === ""
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: LauncherMetrics.iconSize
            source: root.iconSource
        }

        Text {
            visible: root.glyph !== ""
            anchors.verticalCenter: parent.verticalCenter
            width: LauncherMetrics.iconSize
            horizontalAlignment: Text.AlignHCenter
            rightPadding: 6
            text: root.glyph
            font.pixelSize: LauncherMetrics.glyphSize
            font.family: PanelColors.monoFont
            color: root.highlighted ? PanelColors.pillForeground : PanelColors.textDim
            Behavior on color { ColorAnimation { duration: LauncherMetrics.transition } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            font.pixelSize: LauncherMetrics.labelSize
            font.bold: true
            font.family: PanelColors.monoFont
            color: root.highlighted ? PanelColors.pillForeground : PanelColors.textMain
            Behavior on color { ColorAnimation { duration: LauncherMetrics.transition } }
            width: root.width - 60
            elide: Text.ElideRight
        }
    }

    Item { id: overlay; anchors.fill: parent }
}
