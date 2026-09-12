pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/lumina"
    property alias options: options
    Timer { id: saveTimer; interval: 150; onTriggered: settings.writeAdapter() }
    FileView {
        id: settings
        path: root.configDir + "/shell.json"
        watchChanges: true
        onFileChanged: if (!saveTimer.running) reload()
        onAdapterUpdated: saveTimer.restart()
        JsonAdapter {
            id: options
            property JsonObject background: JsonObject {
                property string wallpaperPath: "/usr/share/backgrounds/lumina/lumina-default.png"
                property string thumbnailPath: wallpaperPath
            }
            property JsonObject bar: JsonObject { property int cornerStyle: 1; property bool verbose: true; property bool showAssistant: true; property bool showTray: true; property bool clock24h: true }
            property JsonObject interactions: JsonObject {
                property JsonObject scrolling: JsonObject { property bool fasterTouchpadScroll: true; property real touchpadScrollFactor: 100; property real mouseScrollFactor: 50; property real mouseScrollDeltaThreshold: 120 }
            }
            property JsonObject notifications: JsonObject { property bool dnd: false; property int timeout: 6000 }
            property JsonObject controls: JsonObject { property bool showBrightness: true; property bool showMic: true; property bool showCalendar: true }
            property JsonObject appearance: JsonObject {
                property bool dark: true
                property bool reducedMotion: false
                property real extraBackgroundTint: 0
                property JsonObject transparency: JsonObject {
                    property bool enable: false
                    property bool automatic: false
                    property real backgroundTransparency: 0
                    property real contentTransparency: 0.57
                }
                property JsonObject fonts: JsonObject {
                    property string main: "Google Sans Flex"
                    property string numbers: "Google Sans Flex"
                    property string title: "Google Sans Flex"
                    property string expressive: "Google Sans Flex"
                    property string reading: "Google Sans Flex"
                    property string monospace: "monospace"
                    property string iconNerd: "monospace"
                }
            }
        }
    }
}
