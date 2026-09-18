pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root
    readonly property var players: Mpris.players.values
    property string selectedName: ""
    readonly property var player: players.find(p => p.dbusName === selectedName) || players.find(p => p.isPlaying) || players[0] || null
    function nextPlayer() { if (players.length) selectedName = players[(players.indexOf(player) + 1) % players.length].dbusName; }
    Timer { interval: 1000; running: !!root.player?.isPlaying; repeat: true; onTriggered: root.player?.positionChanged() }
}
