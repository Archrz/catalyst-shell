import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

SectionBase {
    id: root
    accent: PanelColors.launcher

    property string username: "User"
    property string hostname: "Host"
    property string avatarPath: ""
    property string localAvatar: Quickshell.env("HOME") + "/.config/face.jpg"

    property int currentHour: new Date().getHours()

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.currentHour = new Date().getHours()
    }

    readonly property string greeting: {
        if (currentHour >= 5 && currentHour < 12)
            return "caffeine loading."
        if (currentHour >= 12 && currentHour < 18)
            return "still alive, eh? My condolences"
        if (currentHour >= 18 && currentHour < 23)
            return "still fighting the bugs?"
        return "go to bed, ya goblin."
    }

    Component.onCompleted: {
        root.username = Quickshell.env("USER") || "User"
        checkLocalAvatar.running = true
    }

    FileView {
        path: "/etc/hostname"
        onLoaded: root.hostname = text().trim()
    }

    Process {
        id: checkLocalAvatar
        command: [ "test", "-f", root.localAvatar ]
        onExited: (exitCode) => {
            if (exitCode === 0)
                root.avatarPath = "file://" + root.localAvatar
            else
                checkAccountsService.running = true
        }
    }

    Process {
        id: checkAccountsService
        command: [ "sh", "-c", "grep '^Icon=' /var/lib/AccountsService/users/$USER 2>/dev/null | cut -d= -f2" ]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim()
                if (path.length > 0)
                    root.avatarPath = "file://" + path
            }
        }
    }

    Process {
        id: manualPicker
        command: [ "zenity", "--file-selection", "--title=Select Profile Picture" ]
        stdout: StdioCollector {
            onStreamFinished: {
                const selected = text.trim()
                if (selected.length > 0) {
                    saveAvatar.command = [ "cp", selected, root.localAvatar ]
                    saveAvatar.running = true
                }
            }
        }
    }

    Process {
        id: saveAvatar
        onExited: {
            root.avatarPath = ""
            root.avatarPath = "file://" + root.localAvatar
        }
    }

    Row {
        width: parent.width
        spacing: 16
        topPadding: 4
        bottomPadding: 4

        Item {
            id: avatarContainer
            width: 64
            height: 64

            Image {
                id: profileImg
                anchors.fill: parent
                anchors.margins: 2
                source: root.avatarPath
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                visible: status === Image.Ready
                mipmap: true
                smooth: true
                scale: profileMouseArea.containsMouse ? 1.05 : 1.0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }

            Text {
                visible: profileImg.status !== Image.Ready
                anchors.centerIn: parent
                text: ""
                font.pixelSize: 36
                font.family: PanelColors.monoFont
                color: PanelColors.textAccent
                scale: profileMouseArea.containsMouse ? 1.05 : 1.0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                id: borderOverlay
                anchors.fill: parent
                color: "transparent"
                border.width: 2
                border.color: profileMouseArea.containsMouse ? PanelColors.textAccent : PanelColors.profile
                radius: 5
                scale: profileMouseArea.containsMouse ? 1.05 : 1.0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                MouseArea {
                    id: profileMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: manualPicker.running = true
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    color: PanelColors.barBackground
                    radius: 3
                    opacity: profileMouseArea.containsMouse ? 0.8 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰏫"
                        color: PanelColors.textMain
                        font.family: PanelColors.monoFont
                        font.pixelSize: 20
                    }
                }
            }
        }

        Column {
            width: parent.width - avatarContainer.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Text {
                width: parent.width
                text: root.greeting
                font.pixelSize: 12
                font.family: PanelColors.monoFont
                color: PanelColors.textDim
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: root.username
                font.pixelSize: 24
                font.bold: true
                font.family: PanelColors.monoFont
                color: PanelColors.textAccent
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: "@" + root.hostname
                font.pixelSize: 13
                font.family: PanelColors.monoFont
                color: PanelColors.profile
                opacity: 0.9
                elide: Text.ElideRight
            }
        }
    }
}
