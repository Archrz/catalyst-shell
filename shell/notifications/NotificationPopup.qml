import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../dashboard"
import "../theme"

PanelWindow {
    id: root
    required property var screen

    anchors { bottom: true; right: true }

    implicitWidth:  440
    implicitHeight: 1000

    color:         "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayershell.Overlay

    mask: Region { item: cardColumn }

    NotificationServer {
        id: server
        actionsSupported:        true
        imageSupported:          true
        bodySupported:           true
        bodyMarkupSupported:     true
        persistenceSupported:    true
        bodyHyperlinksSupported: true

        onNotification: (notif) => {
            NotificationState.add(notif)
            if (!NotificationState.dndOn)
                notif.tracked = true
        }
    }

    // Card stack
    Column {
        id: cardColumn
        spacing: 8
        anchors {
            bottom:       parent.bottom
            right:        parent.right
            bottomMargin: 10
            rightMargin:  10
        }

        Repeater {
            model: server.trackedNotifications

            Item {
                id:       wrapper
                required property var modelData
                width:    400

                // Null guard during delegate teardown
                height: (card && card.isExiting) ? 0 : (card ? card.implicitHeight : 0)

                Behavior on height {
                    enabled: card ? card.isExiting : false
                    NumberAnimation {
                        duration:    300
                        easing.type: Easing.OutQuart
                    }
                }

                NotificationCard {
                    id:           card
                    notification: wrapper.modelData
                    anchors.bottom: parent.bottom
                }
            }
        }
    }
}
