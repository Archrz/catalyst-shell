pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property string current: ""
    signal changed(string name)

    function update(name) {
        if (!name || name === current)
            return
        current = name
        changed(name)
    }
}
