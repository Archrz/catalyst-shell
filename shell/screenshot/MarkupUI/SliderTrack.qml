import QtQuick

Rectangle {
    id: track
    property real value: 0
    signal moved(real v)
    width: parent.width; height: 20; radius: 10

    Rectangle {
        x: track.value * (track.width - 20)
        width: 20; height: 20; radius: 10
        color: "white"; border.color: "#777"; border.width: 1
    }
    MouseArea {
        anchors.fill: parent
        function pick(mx) { track.moved(Math.max(0, Math.min(1, mx / width))) }
        onPressed: mouse => pick(mouse.x)
        onPositionChanged: mouse => { if (pressed) pick(mouse.x) }
    }
}
