import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
ShellRoot {
    readonly property color clrBg: "#000000"
    readonly property color clrBgAlt: "#0d0d0d"
    readonly property color clrFg: "#e6e1cfdd"
    readonly property color clrFgDim: "#2d3640"
    readonly property color clrAccent: "#ffb454"
    readonly property color clrBorder: "#2d3640"
    readonly property color clrUrgent: "#f07178"
    readonly property color clrReboot: "#ffb454"
    readonly property color clrSession: "#a6e3a1"
    readonly property string fontMain: "JetBrainsMono Nerd Font"
    readonly property int radiusLarge: 12
    readonly property int radiusMed: 8
    readonly property string currentUser: Quickshell.env("USER") || Quickshell.env("LOGNAME") || "user"
    readonly property url wallpaperSource: "file://" + Quickshell.env("HOME") + "/.cache/catalyst/lockscreen-wallpaper.png"

    WlSessionLock {
        id: sessionLock
        locked: true

        WlSessionLockSurface {
            Rectangle {
                id: windowBase
                anchors.fill: parent
                color: "black"

                Item {
                    id: rootSurface
                    anchors.fill: parent
                    opacity: 0

                    NumberAnimation {
                        id: fadeInAnim
                        target: rootSurface
                        property: "opacity"
                        to: 1
                        duration: 400
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        id: fadeOutAnim
                        target: rootSurface
                        property: "opacity"
                        to: 0
                        duration: 400
                        easing.type: Easing.InCubic
                        onFinished: {
                            sessionLock.locked = false
                            Qt.quit()
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: clrBg
                    }

                    Image {
                        anchors.fill: parent
                        source: wallpaperSource
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready

                        Rectangle {
                            anchors.fill: parent
                            color: "black"
                            opacity: 0.2
                        }
                    }

                    PamContext {
                        id: pam
                        config: "login"
                        user: currentUser

                        onCompleted: result => {
                            if (result === PamResult.Success) {
                                fadeOutAnim.start()
                            } else {
                                passwordField.text = ""
                                passwordField.forceActiveFocus()
                                shakeAnim.start()
                            }
                        }

                        onError: _error => {
                            passwordField.text = ""
                            passwordField.forceActiveFocus()
                            shakeAnim.start()
                        }

                        onPamMessage: {
                            if (pam.responseRequired) {
                                pam.respond(passwordField.text)
                            }
                        }
                    }

                    Rectangle {
                        id: card
                        anchors.centerIn: parent
                        width: 360
                        height: cardLayout.implicitHeight + 48
                        radius: radiusLarge
                        color: clrBg
                        border.width: 0

                        SequentialAnimation {
                            id: shakeAnim
                            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; from: 0; to: 10; duration: 50; easing.type: Easing.OutQuad }
                            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; from: 10; to: -10; duration: 50; easing.type: Easing.OutQuad }
                            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; from: -10; to: 10; duration: 50; easing.type: Easing.OutQuad }
                            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; from: 10; to: 0; duration: 50; easing.type: Easing.OutQuad }
                        }

                        ColumnLayout {
                            id: cardLayout
                            anchors.centerIn: parent
                            width: parent.width - 48
                            spacing: 12

                            Rectangle {
                                Layout.fillWidth: true
                                height: 38
                                radius: radiusMed
                                color: clrBorder
                                antialiasing: true

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    spacing: 12
                                    Text { text: "\uf007"; font.family: fontMain; font.pixelSize: 16; color: clrAccent }
                                    Text {
                                        Layout.fillWidth: true
                                        text: currentUser
                                        font.pixelSize: 14
                                        font.bold: true
                                        font.family: fontMain
                                        color: clrAccent
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                radius: radiusMed
                                color: clrBgAlt
                                border.width: passwordField.activeFocus ? 3 : 0
                                border.color: clrAccent

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 12
                                    Text { text: "\uf084"; font.family: fontMain; font.pixelSize: 16; color: passwordField.activeFocus ? clrAccent : clrFgDim }
                                    TextInput {
                                        id: passwordField
                                        Layout.fillWidth: true
                                        verticalAlignment: TextInput.AlignVCenter
                                        echoMode: TextInput.Password
                                        passwordCharacter: "•"
                                        font.pixelSize: 14
                                        font.family: fontMain
                                        color: clrFg
                                        focus: true
                                        activeFocusOnTab: true
                                        KeyNavigation.tab: loginButton
                                        KeyNavigation.backtab: shutdownButton
                                        onAccepted: rootSurface.loginAction()

                                        Text {
                                            anchors.fill: parent
                                            text: "Password..."
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 14
                                            font.family: fontMain
                                            color: clrFgDim
                                            visible: passwordField.text.length === 0 && !passwordField.activeFocus
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: loginButton
                                Layout.fillWidth: true
                                Layout.preferredHeight: 38
                                radius: radiusMed
                                activeFocusOnTab: true
                                antialiasing: true
                                color: (loginMa.containsMouse || loginButton.activeFocus) ? Qt.lighter(clrAccent, 1.15) : clrAccent
                                scale: (loginMa.containsMouse || loginButton.activeFocus) ? 1.03 : 1.0
                                border.width: loginButton.activeFocus ? 3 : 0
                                border.color: Qt.lighter(clrAccent, 1.3)
                                KeyNavigation.tab: logoutButton
                                KeyNavigation.backtab: passwordField

                                Keys.onPressed: function(event) {
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                        rootSurface.loginAction()
                                        event.accepted = true
                                    }
                                }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 12
                                    Text { text: "\uf090"; font.family: fontMain; font.pixelSize: 16; color: clrBg }
                                    Text { text: "Login"; font.family: fontMain; font.bold: true; font.pixelSize: 14; color: clrBg }
                                }

                                MouseArea {
                                    id: loginMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: rootSurface.loginAction()
                                }

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }
                            }
                        }
                    }

                    Item {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.margins: 12
                        height: 40
                        width: logoutText.implicitWidth + 28

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: clrBgAlt
                        }

                        Rectangle {
                            id: logoutButton
                            anchors.centerIn: parent
                            implicitHeight: 28
                            implicitWidth: logoutText.implicitWidth + 16
                            radius: 5
                            antialiasing: true
                            activeFocusOnTab: true
                            color: (logoutMa.containsMouse || logoutButton.activeFocus) ? Qt.lighter(clrSession, 1.15) : clrSession
                            scale: (logoutMa.containsMouse || logoutButton.activeFocus) ? 1.03 : 1.0
                            transformOrigin: Item.Center
                            border.width: logoutButton.activeFocus ? 3 : 0
                            border.color: Qt.lighter(clrSession, 1.3)
                            KeyNavigation.tab: rebootButton
                            KeyNavigation.backtab: loginButton

                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                    Quickshell.execDetached(["mmsg", "dispatch", "quit"])
                                    event.accepted = true
                                }
                            }

                            Text {
                                id: logoutText
                                anchors.centerIn: parent
                                text: "\uf2f5 Logout"
                                font.pixelSize: 16
                                font.bold: true
                                font.family: fontMain
                                color: clrBg
                            }

                            MouseArea {
                                id: logoutMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["mmsg", "dispatch", "quit"])
                            }

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }
                        }
                    }

                    Item {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.margins: 12
                        height: 40
                        width: powerRow.implicitWidth + 12

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: clrBgAlt
                        }

                        Row {
                            id: powerRow
                            anchors.centerIn: parent
                            spacing: 6

                            Rectangle {
                                id: rebootButton
                                implicitHeight: 28
                                implicitWidth: rebootText.implicitWidth + 16
                                radius: 5
                                antialiasing: true
                                activeFocusOnTab: true
                                color: (rebootMa.containsMouse || rebootButton.activeFocus) ? Qt.lighter(clrReboot, 1.15) : clrReboot
                                scale: (rebootMa.containsMouse || rebootButton.activeFocus) ? 1.03 : 1.0
                                transformOrigin: Item.Center
                                border.width: rebootButton.activeFocus ? 3 : 0
                                border.color: Qt.lighter(clrReboot, 1.3)
                                KeyNavigation.tab: shutdownButton
                                KeyNavigation.backtab: logoutButton

                                Keys.onPressed: function(event) {
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                        Quickshell.execDetached(["systemctl", "reboot"])
                                        event.accepted = true
                                    }
                                }

                                Text {
                                    id: rebootText
                                    anchors.centerIn: parent
                                    text: "\uf079 Reboot"
                                    font.pixelSize: 16
                                    font.bold: true
                                    font.family: fontMain
                                    color: clrBg
                                }

                                MouseArea {
                                    id: rebootMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                                }

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }
                            }

                            Rectangle {
                                id: shutdownButton
                                implicitHeight: 28
                                implicitWidth: shutdownText.implicitWidth + 16
                                radius: 5
                                antialiasing: true
                                activeFocusOnTab: true
                                color: (shutdownMa.containsMouse || shutdownButton.activeFocus) ? Qt.lighter(clrUrgent, 1.15) : clrUrgent
                                scale: (shutdownMa.containsMouse || shutdownButton.activeFocus) ? 1.03 : 1.0
                                transformOrigin: Item.Center
                                border.width: shutdownButton.activeFocus ? 3 : 0
                                border.color: Qt.lighter(clrUrgent, 1.3)
                                KeyNavigation.tab: passwordField
                                KeyNavigation.backtab: rebootButton

                                Keys.onPressed: function(event) {
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                        Quickshell.execDetached(["systemctl", "poweroff"])
                                        event.accepted = true
                                    }
                                }

                                Text {
                                    id: shutdownText
                                    anchors.centerIn: parent
                                    text: "\uf011 Shutdown"
                                    font.pixelSize: 16
                                    font.bold: true
                                    font.family: fontMain
                                    color: clrBg
                                }

                                MouseArea {
                                    id: shutdownMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                                }

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }
                            }
                        }
                    }

                    function loginAction() {
                        if (passwordField.text.length === 0) return
                        if (pam.active) return
                        if (!pam.start()) shakeAnim.start()
                    }

                    Component.onCompleted: {
                        passwordField.forceActiveFocus()
                        fadeInAnim.start()
                    }
                }
            }
        }
    }
}
