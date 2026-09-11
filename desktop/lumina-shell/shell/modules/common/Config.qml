pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/lumina"
    property alias options: options
    FileView {
        id: settings
        path: root.configDir + "/shell.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        JsonAdapter {
            id: options
            property JsonObject background: JsonObject {
                property string wallpaperPath: "/usr/share/backgrounds/lumina/lumina-default.png"
                property string thumbnailPath: wallpaperPath
            }
            property JsonObject bar: JsonObject { property int cornerStyle: 1; property bool verbose: true }
            property JsonObject appearance: JsonObject {
                property real extraBackgroundTint: 0
                property JsonObject transparency: JsonObject {
                    property bool enable: false
                    property bool automatic: false
                    property real backgroundTransparency: 0
                    property real contentTransparency: 1
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
