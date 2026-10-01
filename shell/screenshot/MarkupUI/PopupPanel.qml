import QtQuick

Rectangle {
    default property alias content: col.data
    property alias spacing: col.spacing
    z: 10
    color: "#1a1a1a"; radius: 8
    border.color: "#555"; border.width: 1
    height: col.height + 24

    Column { id: col; anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 } }
}
