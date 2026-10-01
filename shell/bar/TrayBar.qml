import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "widgets"
import "../theme"

Row {
    id: root
    spacing: 4

    function trayHidden(item) {
        const id = (item.id || "").toLowerCase()
        if (id.startsWith("chrome_status"))
            return true
        if (id.includes("cursor"))
            return true
        return false
    }

    Repeater {
        model: SystemTray.items
        delegate: Rectangle {
            id: trayDelegate
            required property SystemTrayItem modelData

            visible: !root.trayHidden(trayDelegate.modelData)
            implicitWidth: visible ? 20 : 0
            implicitHeight: visible ? 20 : 0
            radius: 4
            color: trayMouse.containsMouse ? Qt.lighter(PanelColors.tray, 1.35) : PanelColors.tray
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            scale: trayMouse.containsMouse ? 1.03 : 1.0

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }

            IconImage {
                anchors.centerIn: parent
                implicitSize: 14
                source: trayDelegate.modelData.icon
                mipmap: true
            }

            Text {
                anchors.centerIn: parent
                visible: trayDelegate.modelData.icon === ""
                text: (trayDelegate.modelData.title || trayDelegate.modelData.id || "?").charAt(0).toUpperCase()
                font.pixelSize: 10
                font.bold: true
                font.family: PanelColors.monoFont
                color: PanelColors.textMain
            }

            MouseArea {
                id: trayMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        if (trayDelegate.modelData.hasMenu) {
                            if (TrayState.visible && TrayState.activeItem === trayDelegate.modelData) {
                                TrayState.hide()
                                return
                            }
                            SessionState.closeAllPopups()
                            const pos = trayDelegate.mapToItem(null, 0, 0)
                            TrayState.show(trayDelegate.modelData, pos.x, pos.y)
                        }
                    } else {
                        if (trayDelegate.modelData.onlyMenu) {
                            if (TrayState.visible && TrayState.activeItem === trayDelegate.modelData) {
                                TrayState.hide()
                                return
                            }
                            SessionState.closeAllPopups()
                            const pos = trayDelegate.mapToItem(null, 0, 0)
                            TrayState.show(trayDelegate.modelData, pos.x, pos.y)
                        } else {
                            trayDelegate.modelData.activate()
                        }
                    }
                }

                onWheel: (wheel) => {
                    trayDelegate.modelData.scroll(wheel.angleDelta.y, false)
                }
            }
        }
    }
}
