import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    anchors.fill: parent
    color: root.clrBg
    visible: true
    opacity: 1

    property color clrBg: (typeof config !== 'undefined' && config.background_color) ? config.background_color : "#000000"
    property color clrBgAlt: "#0d0d0d"
    property color clrFg: "#e6e1cfdd"
    property color clrFgDim: "#2d3640"
    property color clrAccent: (typeof config !== 'undefined' && config.accent_color) ? config.accent_color : "#ffb454"
    property color clrBorder: "#2d3640"
    property color clrUrgent: (typeof config !== 'undefined' && config.urgent_color) ? config.urgent_color : "#f07178"
    property color clrReboot: "#ffb454"
    property color clrSession: "#a6e3a1"

    property string fontMain: (typeof config !== 'undefined' && config.font) ? config.font : "JetBrainsMono Nerd Font"
    property int radiusLarge: 12
    property int radiusMed: 8

    property int selectedIndex: (typeof userModel !== 'undefined' && userModel) ? Math.max(0, userModel.lastIndex) : 0
    property int sessionIndex: (typeof sessionModel !== 'undefined' && sessionModel) ? Math.max(0, sessionModel.lastIndex) : 0
    property string sessionLabel: "session"
    property string currentUsername: (typeof sddm !== 'undefined') ? (sddm.lastUser || "") : ""

    onSelectedIndexChanged: updateSessionLabel()

    Image {
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: status === Image.Ready

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.2
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 360
        height: cardLayout.implicitHeight + 48
        radius: root.radiusLarge
        color: root.clrBg
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

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    id: userRepeater
                    model: (typeof userModel !== 'undefined') ? userModel : null

                    delegate: Rectangle {
                        id: userDelegate
                        readonly property bool isActive: index === root.selectedIndex
                        Layout.fillWidth: true
                        height: 38
                        radius: root.radiusMed
                        color: isActive ? root.clrBorder : (userMa.containsMouse || userDelegate.activeFocus ? root.clrBgAlt : "transparent")
                        antialiasing: true
                        scale: (userMa.containsMouse || userDelegate.activeFocus) ? 1.03 : 1.0
                        transformOrigin: Item.Center
                        border.width: userDelegate.activeFocus ? 3 : 0
                        border.color: root.clrAccent
                        activeFocusOnTab: true
                        KeyNavigation.tab: index < userRepeater.count - 1 ? userRepeater.itemAt(index + 1) : passwordField
                        KeyNavigation.backtab: index > 0 ? userRepeater.itemAt(index - 1) : shutdownButton

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                root.selectedIndex = index
                                root.currentUsername = model.name
                                passwordField.forceActiveFocus()
                                event.accepted = true
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            spacing: 12
                            Text { text: "\uf007"; font.family: root.fontMain; font.pixelSize: 16; color: isActive ? root.clrAccent : root.clrFg }
                            Text {
                                Layout.fillWidth: true
                                text: model.name || "user"
                                font.pixelSize: 14
                                font.bold: isActive
                                font.family: root.fontMain
                                color: isActive ? root.clrAccent : root.clrFg
                            }
                        }

                        MouseArea {
                            id: userMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: function(mouse) {
                                root.selectedIndex = index
                                root.currentUsername = model.name
                                passwordField.forceActiveFocus()
                            }
                        }

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: root.radiusMed
                color: root.clrBgAlt
                border.width: passwordField.activeFocus ? 3 : 0
                border.color: root.clrAccent

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12
                    Text { text: "\uf084"; font.family: root.fontMain; font.pixelSize: 16; color: passwordField.activeFocus ? root.clrAccent : root.clrFgDim }
                    TextInput {
                        id: passwordField
                        Layout.fillWidth: true
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        font.pixelSize: 14
                        font.family: root.fontMain
                        color: root.clrFg
                        activeFocusOnTab: true
                        KeyNavigation.tab: loginButton
                        KeyNavigation.backtab: userRepeater.count > 0 ? userRepeater.itemAt(userRepeater.count - 1) : shutdownButton
                        onAccepted: loginAction()

                        Text {
                            anchors.fill: parent
                            text: "Password..."
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                            font.family: root.fontMain
                            color: root.clrFgDim
                            visible: passwordField.text.length === 0 && !passwordField.activeFocus
                        }
                    }
                }
            }

            Rectangle {
                id: loginButton
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: root.radiusMed
                activeFocusOnTab: true
                antialiasing: true
                color: (loginMa.containsMouse || loginButton.activeFocus) ? Qt.lighter(root.clrAccent, 1.15) : root.clrAccent
                scale: (loginMa.containsMouse || loginButton.activeFocus) ? 1.03 : 1.0
                border.width: loginButton.activeFocus ? 3 : 0
                border.color: Qt.lighter(root.clrAccent, 1.3)
                KeyNavigation.tab: sessionPill
                KeyNavigation.backtab: passwordField

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        loginAction()
                        event.accepted = true
                    }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    Text { text: "\uf090"; font.family: root.fontMain; font.pixelSize: 16; color: root.clrBg }
                    Text { text: "Login"; font.family: root.fontMain; font.bold: true; font.pixelSize: 14; color: root.clrBg }
                }

                MouseArea {
                    id: loginMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: function(mouse) { loginAction() }
                }

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }
            }
        }
    }

    BarContainer {
        id: bottomLeftBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 12
        bgColor: root.clrBgAlt

        PillButton {
            id: sessionPill
            label: "\uf03a " + root.sessionLabel
            pillColor: root.clrSession
            textColor: root.clrBg
            fontMain: root.fontMain
            KeyNavigation.tab: rebootButton
            KeyNavigation.backtab: loginButton
            onClicked: sessionMenuContainer.toggle()
        }
    }

    BarContainer {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 12
        spacing: 6
        bgColor: root.clrBgAlt

        PillButton {
            id: rebootButton
            label: "\uf079 Reboot"
            pillColor: root.clrReboot
            textColor: root.clrBg
            fontMain: root.fontMain
            KeyNavigation.tab: shutdownButton
            KeyNavigation.backtab: sessionPill
            onClicked: sddm.reboot()
        }

        PillButton {
            id: shutdownButton
            label: "\uf011 Shutdown"
            pillColor: root.clrUrgent
            textColor: root.clrBg
            fontMain: root.fontMain
            KeyNavigation.tab: userRepeater.count > 0 ? userRepeater.itemAt(0) : passwordField
            KeyNavigation.backtab: rebootButton
            onClicked: sddm.powerOff()
        }
    }

    Item {
        id: sessionMenuContainer
        width: 180
        height: sessionColumn.implicitHeight + 20
        anchors.bottom: bottomLeftBar.top
        anchors.left: bottomLeftBar.left
        anchors.bottomMargin: 10
        visible: animState !== "closed"
        enabled: animState !== "closed"
        property string animState: "closed"
        function open() {
            animState = "open"
            Qt.callLater(function() { sessionRepeater.itemAt(root.sessionIndex).forceActiveFocus() })
        }
        function close() { animState = "closing"; sessionPill.forceActiveFocus() }
        function toggle() { animState === "open" ? close() : open() }

        Rectangle {
            id: innerSessionRect
            anchors.fill: parent
            radius: root.radiusLarge
            color: root.clrBg
            border.color: root.clrSession
            border.width: 2
            clip: true

            states: [
                State { name: "open"; when: sessionMenuContainer.animState === "open"; PropertyChanges { target: innerSessionRect; y: 0; opacity: 1.0 } },
                State { name: "closing"; when: sessionMenuContainer.animState === "closing"; PropertyChanges { target: innerSessionRect; y: 20; opacity: 0.0 } }
            ]

            transitions: [
                Transition {
                    to: "open"
                    SequentialAnimation {
                        PropertyAction { target: innerSessionRect; property: "y"; value: 20 }
                        PropertyAction { target: innerSessionRect; property: "opacity"; value: 0.0 }
                        ParallelAnimation {
                            NumberAnimation { target: innerSessionRect; property: "y"; to: 0; duration: 250; easing.type: Easing.OutExpo }
                            NumberAnimation { target: innerSessionRect; property: "opacity"; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
                        }
                    }
                },
                Transition {
                    to: "closing"
                    SequentialAnimation {
                        ParallelAnimation {
                            NumberAnimation { target: innerSessionRect; property: "y"; to: 20; duration: 180; easing.type: Easing.InCubic }
                            NumberAnimation { target: innerSessionRect; property: "opacity"; to: 0.0; duration: 150; easing.type: Easing.InCubic }
                        }
                        ScriptAction { script: sessionMenuContainer.animState = "closed" }
                    }
                }
            ]

            Column {
                id: sessionColumn
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 10
                spacing: 4

                Repeater {
                    id: sessionRepeater
                    model: (typeof sessionModel !== 'undefined') ? sessionModel : null
                    delegate: Rectangle {
                        id: sessionDelegate
                        readonly property bool isActive: root.sessionIndex === index
                        width: sessionColumn.width
                        height: 34
                        radius: 6
                        color: isActive ? root.clrSession : root.clrBgAlt
                        activeFocusOnTab: false
                        border.width: sessionDelegate.activeFocus ? 2 : 0
                        border.color: Qt.lighter(root.clrSession, 1.3)

                        KeyNavigation.up: index > 0 ? sessionRepeater.itemAt(index - 1) : null
                        KeyNavigation.down: index < sessionRepeater.count - 1 ? sessionRepeater.itemAt(index + 1) : null

                        Keys.onReturnPressed: function(event) { root.sessionIndex = index; updateSessionLabel(); sessionMenuContainer.close(); event.accepted = true }
                        Keys.onEnterPressed: function(event) { root.sessionIndex = index; updateSessionLabel(); sessionMenuContainer.close(); event.accepted = true }
                        Keys.onEscapePressed: function(event) { sessionMenuContainer.close(); event.accepted = true }
                        Keys.onTabPressed: function(event) { sessionMenuContainer.close(); passwordField.forceActiveFocus(); event.accepted = true }
                        Keys.onBacktabPressed: function(event) { sessionMenuContainer.close(); sessionPill.forceActiveFocus(); event.accepted = true }
                        Rectangle {
                            visible: !isActive
                            width: 3; height: parent.height - 12; radius: 2; color: root.clrSession
                            anchors.left: parent.left; anchors.leftMargin: 4; anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter
                            text: model.name || "Session"
                            color: isActive ? root.clrBg : root.clrFg
                            font.pixelSize: 13; font.bold: true; font.family: root.fontMain
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: function(mouse) {
                                root.sessionIndex = index
                                updateSessionLabel()
                                sessionMenuContainer.close()
                            }
                        }
                    }
                }
            }
        }
    }

    function sessionCount() { return (typeof sessionModel !== 'undefined' && sessionModel) ? sessionModel.count : 0 }

    function loginAction() {
        if (typeof sddm === 'undefined') return
        if (typeof userModel === 'undefined' || !userModel || userModel.count === 0) return
        var username = root.currentUsername || sddm.lastUser
        if (username) sddm.login(username, passwordField.text, root.sessionIndex)
    }

    function updateSessionLabel() {
        var count = sessionCount()
        if (count > 0 && root.sessionIndex < count) {
            var idx = sessionModel.index(root.sessionIndex, 0)
            root.sessionLabel = sessionModel.data(idx, Qt.UserRole) || "Session"
        }
    }

    NumberAnimation { id: fadeOutAnim; target: root; property: "opacity"; to: 0; duration: 400; running: false; easing.type: Easing.InCubic }

    Connections {
        target: sddm
        function onLoginFailed() {
            shakeAnim.start()
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
        function onLoginSucceeded() {
            fadeOutAnim.start()
        }
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            try {
                updateSessionLabel()
                if (typeof userModel !== 'undefined' && userModel && userModel.count > 0) {
                    var idx = userModel.index(root.selectedIndex, 0)
                    root.currentUsername = userModel.data(idx, Qt.UserRole + 1) || (typeof sddm !== 'undefined' ? sddm.lastUser : "")
                }
                passwordField.forceActiveFocus()
            } catch (e) {
                passwordField.forceActiveFocus()
            }
        })
    }
}
