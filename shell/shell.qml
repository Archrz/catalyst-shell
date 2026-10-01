//@ pragma IconTheme Papirus-Dark
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "polkit"
import "bar"
import "notifications"
import "osd"
import "dashboard"
import "launcher"
import "screenshot"
import "colorpicker"
import "theme"

ShellRoot {
    Component.onCompleted: WallpaperState.restore()

    IpcHandler {
        target: "dashboard"
        function toggle(): void {
            SessionState.dashboardVisible = !SessionState.dashboardVisible
        }
    }

    IpcHandler {
        target: "idle"
        function trigger(): void { idleGrimProc.running = true }
    }

    // Idle overlay
    IdleMonitor {
        id: idleMonitor
        timeout: 300
        enabled: !SystemTogglesState.caffeineOn
        onIsIdleChanged: {
            if (isIdle) idleGrimProc.running = true
        }
    }

    Process {
        id: idleGrimProc
        running: false
        command: ["sh", "-c", "grim /tmp/qs-idle-raw.png && magick /tmp/qs-idle-raw.png -blur 0x20 /tmp/qs-idle-capture.png"]
        onExited: exitCode => {
            running = false
            if (exitCode !== 0) return
            idleOverlayProcess.running = false
            idleOverlayProcess.running = true
        }
    }

    Process {
        id: idleOverlayProcess
        command: ["qs", "-p", Quickshell.shellPath("idle-overlay")]
        running: false
        onExited: () => { running = false }
    }

    Process {
        id: layoutWatch
        command: [ "mmsg", "watch", "keyboardlayout" ]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                const trimmed = line.trim()
                if (trimmed.length === 0) return
                try {
                    const json = JSON.parse(trimmed)
                    if (json.layout)
                        KeyboardLayoutState.update(json.layout)
                } catch (e) {
                    console.warn("keyboard layout parse error:", e, trimmed)
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: panelWin
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            readonly property bool barHidden: ToplevelManager.activeToplevel && ToplevelManager.activeToplevel.fullscreen
            visible: !barHidden
            implicitHeight: 24
            color: "transparent"
            exclusiveZone: barHidden ? 0 : implicitHeight
            WlrLayershell.layer: WlrLayershell.Overlay
            Bar { id: bar; anchors.fill: parent }

            function popupX(widget, pWidth) {
                return Math.min(
                    bar.rightContainer.x + bar.rightBar.x + widget.x + widget.width / 2 - pWidth / 2,
                    bar.rightContainer.x + bar.rightContainer.width - pWidth
                )
            }

            function centerPopupX(pWidth) {
                return Math.round(panelWin.screen.width / 2 - pWidth / 2)
            }

            Repeater {
                model: [
                    { "source": "osd/AudioPopup.qml", "widget": bar.rightBar.audioWidget },
                    { "source": "osd/SessionPopup.qml", "widget": bar.rightBar.sessionWidget },
                    { "source": "osd/TrayPopup.qml", "widget": bar.rightBar.trayBar },
                    { "source": "osd/CalendarPopup.qml", "widget": bar.rightBar.dateWidget }
                ]
                delegate: Loader {
                    required property var modelData
                    source: modelData.source
                    asynchronous: true
                    onLoaded: {
                        item.anchor.window = panelWin
                        item.anchor.rect.y = Qt.binding(function() { return panelWin.height + 4 })
                        item.anchor.rect.x = Qt.binding(function() { return panelWin.popupX(modelData.widget, item.implicitWidth) })
                    }
                }
            }

            MediaPopup {
                anchor.window: panelWin
                anchor.rect.x: panelWin.centerPopupX(implicitWidth)
                anchor.rect.y: panelWin.height + 4
            }

            Dashboard {
                screenObj: modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        NotificationPopup {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens
        OsdWindow {
            required property var modelData
            screen: modelData
        }
    }

    PolkitDialog {}
    ColorPickerUI {}
    AppLauncher {}
    Loader { id: markupLoader }
    ScreenshotUI {
        onMarkupReady: (w, h) => {
            markupLoader.sourceComponent = null
            markupLoader.sourceComponent = markupComp
            markupLoader.item.open(w, h)
        }
    }
    Component { id: markupComp; MarkupUI {} }
}
