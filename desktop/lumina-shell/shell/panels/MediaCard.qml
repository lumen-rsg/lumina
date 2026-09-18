// Info, art, transport and wavy seek bar adapted from ii/mediaControls/PlayerControl.qml.
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Rectangle {
    id: root
    property var player: Media.player
    readonly property string art: player?.trackArtUrl || ""
    implicitHeight: 154; radius: 20; color: Appearance.colors.colLayer1
    RowLayout {
        anchors.fill: parent; anchors.margins: 12; spacing: 12
        Rectangle {
            Layout.preferredWidth: 86; Layout.preferredHeight: 110; radius: 14; color: Appearance.colors.colLayer2; clip: true
            Image { id: cover; anchors.fill: parent; asynchronous: true; fillMode: Image.PreserveAspectCrop; source: /^(file|https?):/.test(root.art) ? root.art : "" }
            MaterialSymbol { anchors.centerIn: parent; text: "music_note"; iconSize: 34; visible: cover.status !== Image.Ready; opacity: 0.5 }
        }
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 2
            RowLayout {
                StyledText { Layout.fillWidth: true; text: root.player?.identity || "Media"; textFormat: Text.PlainText; font.pixelSize: 11; opacity: 0.55; elide: Text.ElideRight }
                ActionButton { visible: Media.players.length > 1; symbol: "swap_horiz"; Accessible.name: "Switch media player"; implicitHeight: 26; onClicked: Media.nextPlayer() }
            }
            StyledText { Layout.fillWidth: true; text: root.player?.trackTitle || (root.player ? "Untitled" : "Nothing playing"); textFormat: Text.PlainText; elide: Text.ElideRight; font.pixelSize: 16; font.weight: Font.DemiBold }
            StyledText { Layout.fillWidth: true; text: root.player?.trackArtist || ""; textFormat: Text.PlainText; elide: Text.ElideRight; font.pixelSize: 12; opacity: 0.65 }
            RowLayout {
                Layout.fillWidth: true
                ActionButton { objectName: "mediaPrevious"; symbol: "skip_previous"; Accessible.name: "Previous track"; enabled: root.player?.canGoPrevious ?? false; onClicked: root.player.previous() }
                ActionButton { objectName: "mediaToggle"; symbol: root.player?.isPlaying ? "pause" : "play_arrow"; Accessible.name: root.player?.isPlaying ? "Pause playback" : "Play"; enabled: root.player?.canTogglePlaying ?? false; toggled: root.player?.isPlaying ?? false; onClicked: root.player.togglePlaying() }
                ActionButton { objectName: "mediaNext"; symbol: "skip_next"; Accessible.name: "Next track"; enabled: root.player?.canGoNext ?? false; onClicked: root.player.next() }
                Item { Layout.fillWidth: true }
                StyledText { text: Productivity.format(root.player?.position ?? 0); font.pixelSize: 11; opacity: 0.6 }
            }
            StyledSlider {
                objectName: "mediaSeek"; Layout.fillWidth: true; implicitHeight: 22
                configuration: StyledSlider.Configuration.Wavy
                enabled: (root.player?.canSeek ?? false) && (root.player?.length ?? 0) > 0
                value: root.player && root.player.length > 0 ? root.player.position / root.player.length : 0
                onMoved: if (enabled) root.player.position = value * root.player.length
            }
        }
    }
}
