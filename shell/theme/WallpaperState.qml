pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string cacheFile:
        Quickshell.env("HOME") + "/.cache/catalyst/last-wallpaper"
    readonly property string defaultImage:
        (Quickshell.env("CATALYST_WALLPAPER_DIR") || Quickshell.env("HOME") + "/catalyst/home/arch/wall") + "/40.jpg"
    readonly property string lockImage:
        Quickshell.env("HOME") + "/.cache/catalyst/lockscreen-wallpaper.png"
    readonly property string sddmImage: "/var/lib/sddm-wallpaper/current"

    function restore() {
        restoreProc.running = false
        restoreProc.running = true
    }

    function apply(path, mediaType, fade) {
        var p = path.replace(/'/g, "'\\''")
        var lock = "'" + lockImage + "'"
        var sddm = "'" + sddmImage + "'"
        var transition = fade
            ? "--transition-type fade --transition-duration 0.8 --transition-fps 60"
            : "--transition-type none"
        var script

        if (mediaType === "video") {
            // Stop image layer, then replace any running video.
            script =
                "pkill -x awww-daemon 2>/dev/null; pkill -x mpvpaper 2>/dev/null; " +
                "mkdir -p \"$HOME/.cache/catalyst\"; " +
                "echo 'video:" + p + "' > \"" + cacheFile + "\"; " +
                "ffmpeg -y -ss 00:00:01 -i '" + p + "' -vframes 1 " + lock + " >/dev/null 2>&1 && cp -f " + lock + " " + sddm + " & " +
                "mpvpaper -f -p -o '--loop-file=inf --no-audio --hwdec=auto' ALL '" + p + "'"
        } else {
            // Stop video only — awww img swaps images in place.
            script =
                "pkill -x mpvpaper 2>/dev/null; " +
                "awww query >/dev/null 2>&1 || { awww-daemon &>/dev/null & " +
                "for i in $(seq 1 20); do sleep 0.1 && awww query >/dev/null 2>&1 && break; done; }; " +
                "mkdir -p \"$HOME/.cache/catalyst\"; " +
                "echo 'image:" + p + "' > \"" + cacheFile + "\"; " +
                "awww img '" + p + "' " + transition + "; " +
                "cp -f '" + p + "' " + lock + "; " +
                "cp -f '" + p + "' " + sddm
        }

        applyProc.command = ["bash", "-c", script]
        applyProc.running = false
        applyProc.running = true
    }

    Process {
        id: restoreProc
        command: ["test", "-f", root.cacheFile]
        onExited: (code) => {
            if (code === 0)
                cacheView.reload()
            else
                root.apply(root.defaultImage, "image", false)
        }
    }

    FileView {
        id: cacheView
        path: root.cacheFile
        onLoaded: {
            const line = text().trim()
            const colon = line.indexOf(":")
            if (colon < 1) {
                root.apply(root.defaultImage, "image", false)
                return
            }
            const type = line.slice(0, colon)
            const wall = line.slice(colon + 1)
            checkProc.command = ["test", "-f", wall]
            checkProc._type = type
            checkProc._wall = wall
            checkProc.running = false
            checkProc.running = true
        }
    }

    Process {
        id: checkProc
        property string _type: ""
        property string _wall: ""
        command: ["true"]
        onExited: (code) => {
            if (code === 0)
                root.apply(_wall, _type, false)
            else
                root.apply(root.defaultImage, "image", false)
        }
    }

    Process {
        id: applyProc
        running: false
        command: ["true"]
    }
}
