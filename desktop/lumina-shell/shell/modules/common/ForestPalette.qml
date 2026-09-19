// Original muted-forest palette. Semantic use lives in Theme.qml.
import QtQuick

QtObject {
    readonly property string key: "forest"
    readonly property string displayName: "Muted forest"
    readonly property string description: "Deep evergreen with sage and warm oak"
    readonly property bool dark: true
    readonly property color anchor: "#A8C7A0"

    readonly property color bg: "#101713"
    readonly property color bgAlt: "#151E19"
    readonly property color bgRaised: "#1C2821"
    readonly property color bgOverlay: "#25342B"

    readonly property color accent: "#A8C7A0"
    readonly property color accentAlt: "#89B8A2"
    readonly property color accentWarn: "#D9BD7A"
    readonly property color accentDanger: "#D98C8C"
    readonly property color accentDangerSoft: "#38D98C8C"
    readonly property color accentDangerSubtle: "#2BD98C8C"
    readonly property color accentDangerHover: "#45D98C8C"
    readonly property color accentPink: "#CDA0A7"
    readonly property color accentCyan: "#9BBFC0"
    readonly property color accentPurple: "#B7A6C8"
    readonly property color accentWood: "#C0906D"
    readonly property color accentSoft: "#2FA8C7A0"
    readonly property color accentWoodSoft: "#36C0906D"

    readonly property color fg: "#EDF2EB"
    readonly property color fgDim: "#B2BEB0"
    readonly property color fgFaint: "#8E9E90"
    readonly property color fgDisabled: "#546157"

    readonly property color borderSubtle: "#26362C"
    readonly property color borderDefault: "#385043"
    readonly property color borderStrong: "#617568"

    readonly property color glassBg: "#ED101713"
    readonly property color glassBgStrong: "#F516211B"
    readonly property color glassBorder: "#806E5848"
    readonly property color glassHover: "#2DA8C7A0"
    readonly property color glassActive: "#48A8C7A0"
    readonly property color surfaceHighlight: "#1FFFFAF0"
    readonly property color scrim: "#BD0B100D"
    readonly property color scrimSoft: "#940B100D"
    readonly property color viewportFill: "#26A8C7A0"
    readonly property color shadowColor: "#40000000"

    readonly property var groupColors: [
        "#A8C7A0", "#D98C8C", "#89B8A2", "#B7A6C8",
        "#D9BD7A", "#9BBFC0", "#CDA0A7"
    ]

    readonly property color wallpaperStart: "#19251E"
    readonly property color wallpaperEnd: "#111914"
    readonly property color wallpaperGlowOne: "#575E7E5E"
    readonly property color wallpaperGlowTwo: "#385B7E76"
    readonly property color wallpaperGlowThree: "#387C583D"
    readonly property color wallpaperGlowFour: "#1F777952"
    readonly property color wallpaperContour: "#0987A684"
    readonly property color wallpaperContourDeep: "#210E1711"
    readonly property color wallpaperOverlay: "#18080D09"

    readonly property real shadowSmOpacity: 0.25
    readonly property real shadowMdOpacity: 0.35
    readonly property real shadowLgOpacity: 0.45
}
