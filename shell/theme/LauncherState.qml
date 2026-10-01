pragma Singleton
import QtQuick
import Quickshell


Singleton {
    property bool visible: false

    function toggle() { visible = !visible }
    function show()   { visible = true      }
    function hide()   { visible = false     }
}
