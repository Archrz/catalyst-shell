import QtQuick
import Quickshell
import "../theme"

PopupBase {
    id: root
    implicitWidth:  240
    borderColor:    PanelColors.brightness
    contentHeight:  column.implicitHeight

    Connections {
        target: BrightnessState
        function onPopupVisibleChanged() {
            root.animState = BrightnessState.popupVisible ? "open" : "closing"
            if (BrightnessState.popupVisible) KbdBrightnessState.refresh()
        }
    }

    Column {
        id: column
        anchors { fill: parent; margins: root.padding }
        spacing: 8

        // Screen
        Rectangle {
            width: parent.width; height: 34; radius: 6; color: PanelColors.rowBackground
            Row {
                anchors { fill: parent; margins: root.padding }
                spacing: 8
                Text {
                    text: {
                        if (BrightnessState.brightness >= 80) return "󰃠"
                        if (BrightnessState.brightness >= 40) return "󰃟"
                        return "󰃞"
                    }
                    font.pixelSize: 16; font.family: PanelColors.monoFont
                    color: PanelColors.brightness
                    anchors.verticalCenter: parent.verticalCenter
                }
                PanelSlider {
                    width: parent.width - 64; anchors.verticalCenter: parent.verticalCenter
                    value: BrightnessState.brightness; accentColor: PanelColors.brightness
                    onMoved: (v) => BrightnessState.setBrightness(v)
                }
                Text {
                    text: BrightnessState.brightness + "%"
                    width: 32; font.pixelSize: 12; font.family: PanelColors.monoFont
                    color: PanelColors.textMain
                    horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Keyboard
        Rectangle {
            visible: KbdBrightnessState.available
            width: parent.width; height: 34; radius: 6; color: PanelColors.rowBackground
            Row {
                anchors { fill: parent; margins: root.padding }
                spacing: 8
                Text {
                    text: "󰌌"
                    font.pixelSize: 16; font.family: PanelColors.monoFont
                    color: PanelColors.brightness
                    anchors.verticalCenter: parent.verticalCenter
                }
                PanelSlider {
                    width: parent.width - 64
                    anchors.verticalCenter: parent.verticalCenter
                    from: 0
                    to: KbdBrightnessState.maxBrightness
                    value: KbdBrightnessState.brightness
                    wheelStep: 1
                    accentColor: PanelColors.brightness
                    onMoved: (v) => KbdBrightnessState.setBrightness(v)
                }
                Text {
                    text: KbdBrightnessState.brightness + "/" + KbdBrightnessState.maxBrightness
                    width: 32; font.pixelSize: 12; font.family: PanelColors.monoFont
                    color: PanelColors.textMain
                    horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
