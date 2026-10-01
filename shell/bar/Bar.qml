import QtQuick
import QtQuick.Layouts
import "."
import "widgets"
import "../theme"

Item {
    id: root

    property alias rightContainer: rightContainer
    property alias rightBar: rightBar
    property alias centerContainer: centerContainer
    property alias centerBar: centerBar

    Rectangle {
        id: barStrip
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 24
        color: PanelColors.barBackground
    }

    Rectangle {
        id: leftContainer
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.top: parent.top
        anchors.topMargin: 2
        height: 20
        color: "transparent"
        width: leftBar.implicitWidth + 4

        LeftBar {
            id: leftBar
            anchors.centerIn: parent
        }
    }

    Rectangle {
        id: centerContainer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 2
        height: 20
        color: "transparent"
        width: centerBar.implicitWidth + 4

        CenterBar {
            id: centerBar
            anchors.centerIn: parent
        }
    }

    Rectangle {
        id: rightContainer
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.top: parent.top
        anchors.topMargin: 2
        height: 20
        color: "transparent"
        width: rightBar.implicitWidth + 4

        RightBar {
            id: rightBar
            anchors.centerIn: parent
        }
    }
}
