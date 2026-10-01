import QtQuick

PopupPanel {
    id: picker
    property real lineWidth: 2.5
    property color previewColor: "red"
    signal edited(real w)

    width: 200
    spacing: 10

    SliderTrack {
        color: "#444"
        value: (picker.lineWidth - 1) / 39
        onMoved: v => picker.edited(Math.round(v * 39 + 1))
    }
    Row {
        spacing: 8
        height: 26
        anchors.horizontalCenter: parent.horizontalCenter
        Text {
            text: Math.round(picker.lineWidth)
            color: "#ccc"; font.pixelSize: 13
            width: 22; horizontalAlignment: Text.AlignRight
            anchors.verticalCenter: parent.verticalCenter
        }
        Rectangle {
            width: 140; height: Math.min(picker.lineWidth, 26); radius: height / 2
            color: picker.previewColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
