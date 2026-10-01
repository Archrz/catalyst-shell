import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root

    anchors.bottom: true
    implicitWidth: 260
    implicitHeight: 144
    color: "transparent"
    exclusiveZone: 0
    visible: animState !== "closed"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "osd"

    property string animState: "closed"   // "closed" | "open"
    property string osdType:  "audio"     // "audio" | "brightness" | "keyboard"
    property string keyboardLayout: ""

    // Show
    function show(type) {
        osdType = type
        if (animState === "closed") {
            // Park off-screen before visible — implicitHeight not height at first commit
            osdRect.y       = root.implicitHeight
            osdRect.opacity = 0
        }
        animState = "open"
        fadeOutAnim.stop()
        slideAnim.to = root.implicitHeight - 80 - osdRect.height
        slideAnim.start()
        fadeInAnim.start()
        dismissTimer.restart()
    }

    function showKeyboard(name) {
        keyboardLayout = name
        show("keyboard")
    }

    NumberAnimation { id: slideAnim;   target: osdRect; property: "y";       duration: 250; easing.type: Easing.OutExpo  }
    NumberAnimation { id: fadeInAnim;  target: osdRect; property: "opacity"; to: 1.0; duration: 200; easing.type: Easing.OutCubic }

    Timer {
        id: dismissTimer
        interval: 1800
        onTriggered: fadeOutAnim.start()
    }

    NumberAnimation {
        id: fadeOutAnim
        target: osdRect; property: "opacity"; to: 0
        duration: 300; easing.type: Easing.InCubic
        onStopped: root.animState = "closed"
    }

    // Triggers
    Connections {
        target: BrightnessState
        function onBrightnessChanged() { if (!BrightnessState.popupVisible) root.show("brightness") }
    }

    Connections {
        target: AudioState
        function onVolumeChanged() { if (!AudioState.popupVisible) root.show("audio") }
        function onMutedChanged()  { if (!AudioState.popupVisible) root.show("audio") }
    }

    Connections {
        target: KeyboardLayoutState
        function onChanged(name) { root.showKeyboard(name) }
    }

    // Card
    Rectangle {
        id: osdRect
        width:  root.implicitWidth
        height: 52
        anchors.horizontalCenter: parent.horizontalCenter
        y:      root.implicitHeight
        radius: 10
        color:  PanelColors.popupBackground
        border.width: 2
        border.color: root.osdType === "keyboard"
            ? PanelColors.network
            : (root.osdType === "brightness" ? PanelColors.brightness : PanelColors.audio)
        opacity: 0

        RowLayout {
            anchors.centerIn: parent
            spacing: 12

            Text {
                visible: root.osdType === "keyboard"
                Layout.alignment: Qt.AlignVCenter
                font.pixelSize: 20
                font.family: PanelColors.monoFont
                color: PanelColors.network
                text: "󰌌"
            }

            Text {
                visible: root.osdType === "keyboard"
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.keyboardLayout
                font.pixelSize: 13
                font.bold: true
                font.family: PanelColors.monoFont
                color: PanelColors.textMain
            }

            Text {
                visible: root.osdType !== "keyboard"
                Layout.alignment: Qt.AlignVCenter
                font.pixelSize: 20
                font.family: PanelColors.monoFont
                color: {
                    if (root.osdType === "brightness") return PanelColors.brightness
                    return (AudioState.muted || AudioState.volume === 0)
                        ? PanelColors.textDim : PanelColors.audio
                }
                text: {
                    if (root.osdType === "brightness") {
                        var b = BrightnessState.brightness
                        if (b >= 80) return "󰃠"
                        if (b >= 40) return "󰃟"
                        return "󰃞"
                    }
                    if (AudioState.muted || AudioState.volume === 0) return "󰝟"
                    return "󰕾"
                }
            }

            Rectangle {
                visible: root.osdType !== "keyboard" && !(root.osdType === "audio" && AudioState.muted)
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 150
                height: 6
                radius: 3
                color:  PanelColors.trackBackground

                Rectangle {
                    property real pct: root.osdType === "brightness"
                        ? BrightnessState.brightness / 100
                        : Math.min(AudioState.volume, 100) / 100
                    width:  parent.width * pct
                    height: parent.height
                    radius: parent.radius
                    color:  root.osdType === "brightness" ? PanelColors.brightness : PanelColors.audio
                    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                visible: root.osdType === "audio" && AudioState.muted
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                text: "Muted"
                font.pixelSize: 13; font.bold: true; font.family: PanelColors.monoFont
                color: PanelColors.textDim
            }

            Text {
                visible: root.osdType !== "keyboard" && !(root.osdType === "audio" && AudioState.muted)
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 24
                horizontalAlignment: Text.AlignRight
                text: (root.osdType === "brightness" ? BrightnessState.brightness : AudioState.volume)
                font.pixelSize: 12; font.bold: true; font.family: PanelColors.monoFont
                color: PanelColors.textMain
            }
        }
    }
}
