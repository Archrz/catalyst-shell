import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root

    property var screenObj: null
    readonly property int stateClosed: 0
    readonly property int stateOpen: 1
    readonly property int stateClosing: 2
    property int animState: stateClosed

    readonly property int cardGap: 10
    readonly property int cardPad: 14

    screen: screenObj
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    color: "transparent"
    mask: Region {
        item: dashLayout
    }

    margins.top: cardGap
    margins.left: cardGap
    margins.bottom: cardGap

    implicitWidth: 320
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    HoverHandler { id: rootHover }
    Timer {
        interval: 3000
        running: root.dashboardState === "open" && !rootHover.hovered
        onTriggered: SessionState.dashboardVisible = false
    }

    component DashCard: Rectangle {
        id: dashCard

        property color accent: PanelColors.launcher
        property string label: ""
        property alias header: cardHeader
        property alias headerExtra: headerExtraSlot.data

        radius: 10
        color: PanelColors.popupBackground
        Behavior on color { ColorAnimation { duration: PanelColors.transitionDuration } }
        border.color: accent
        Behavior on border.color { ColorAnimation { duration: PanelColors.transitionDuration } }
        border.width: 2
        clip: true

        opacity: 0.0
        transform: Translate { id: dashCardTranslate; x: -24 }

        state: "closed"

        states: [
            State {
                name: "open"
                PropertyChanges { target: dashCard; opacity: 1.0 }
                PropertyChanges { target: dashCardTranslate; x: 0 }
            },
            State {
                name: "closed"
                PropertyChanges { target: dashCard; opacity: 0.0 }
                PropertyChanges { target: dashCardTranslate; x: -24 }
            }
        ]

        transitions: [
            Transition {
                to: "open"
                ParallelAnimation {
                    NumberAnimation { target: dashCardTranslate; property: "x"; duration: 260; easing.type: Easing.OutExpo }
                    NumberAnimation { target: dashCard; property: "opacity"; duration: 200; easing.type: Easing.OutCubic }
                }
            },
            Transition {
                to: "closed"
                ParallelAnimation {
                    NumberAnimation { target: dashCardTranslate; property: "x"; duration: 200; easing.type: Easing.InCubic }
                    NumberAnimation { target: dashCard; property: "opacity"; duration: 160; easing.type: Easing.InCubic }
                }
            }
        ]

        default property alias content: inner.data

        Rectangle {
            width: 4; height: parent.height - 24; radius: 2
            anchors { left: parent.left; leftMargin: 7; verticalCenter: parent.verticalCenter }
            color: dashCard.accent; opacity: 0.85
        }

        Column {
            id: cardHeader
            anchors {
                top: parent.top; topMargin: root.cardPad
                left: parent.left; leftMargin: 20
                right: parent.right; rightMargin: 16
            }
            spacing: 6

            Row {
                width: parent.width
                Text {
                    text: dashCard.label
                    visible: dashCard.label.length > 0
                    font.pixelSize: 16; font.bold: true; font.family: PanelColors.monoFont
                    color: dashCard.accent
                    width: parent.width - headerExtraSlot.implicitWidth
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                }
                Item {
                    id: headerExtraSlot
                    implicitWidth: childrenRect.width
                    implicitHeight: childrenRect.height
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Rectangle {
                visible: dashCard.label.length > 0
                width: parent.width; height: 2
                color: PanelColors.rowBackground; opacity: 0.6
                Behavior on color { ColorAnimation { duration: 250 } }
            }
            Item {
                width: 1
                height: dashCard.label.length > 0 ? 10 : 0
                visible: dashCard.label.length > 0
            }
        }

        Item {
            id: inner
            anchors {
                top: cardHeader.bottom
                bottom: parent.bottom; bottomMargin: root.cardPad
                left: parent.left; leftMargin: 20
                right: parent.right; rightMargin: 16
            }
        }
    }

    ColumnLayout {
        id: dashLayout
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: root.cardGap

        DashCard {
            id: profileCard
            accent: PanelColors.profile
            label: ""
            Layout.fillWidth: true
            implicitHeight: profileCard.header.implicitHeight + profileInner.implicitHeight + (root.cardPad * 2)
            ProfileSection { id: profileInner; width: parent.width }
        }

        DashCard {
            id: systemCard
            accent: PanelColors.system
            label: "System"
            Layout.fillWidth: true
            implicitHeight: systemCard.header.implicitHeight + systemInner.implicitHeight + (root.cardPad * 2)
            SystemStatsSection { id: systemInner; width: parent.width }
        }

        DashCard {
            id: notifCard
            accent: PanelColors.launcher
            label: "Notifications"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: {
                const base = notifCard.header.implicitHeight + (root.cardPad * 2)
                const maxH = root.height - profileCard.implicitHeight - systemCard.implicitHeight - (root.cardGap * 2)
                return Math.min(base + notifInner.totalHeight + root.cardPad, maxH)
            }

            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: 220; easing.type: Easing.OutExpo }
            }

            headerExtra: Text {
                text: "Clear all"
                font.pixelSize: 11
                font.family: PanelColors.monoFont
                color: clearAllMouse.containsMouse ? PanelColors.error : PanelColors.textDim
                visible: NotificationState.history.count > 0
                MouseArea {
                    id: clearAllMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationState.clearHistory()
                }
            }

            NotificationSection { id: notifInner }
        }
    }

    property string dashboardState: SessionState.dashboardVisible ? "open" : "closed"
    visible: dashboardState === "open" || closeAnim.running

    onDashboardStateChanged: {
        if (dashboardState === "open") {
            closeAnim.stop()
            openAnim.start()
        } else {
            openAnim.stop()
            closeAnim.start()
        }
    }

    SequentialAnimation {
        id: openAnim
        ScriptAction { script: profileCard.state = "open" }
        PauseAnimation { duration: 60 }
        ScriptAction { script: systemCard.state = "open" }
        PauseAnimation { duration: 60 }
        ScriptAction { script: notifCard.state = "open" }
    }

    SequentialAnimation {
        id: closeAnim
        ScriptAction {
            script: {
                profileCard.state = "closed"
                systemCard.state = "closed"
                notifCard.state = "closed"
            }
        }
        PauseAnimation { duration: 280 }
    }
}
