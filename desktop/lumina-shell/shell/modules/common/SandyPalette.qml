// Calm light palette built around the user's warm sand anchor.
import QtQuick

QtObject {
    readonly property string key: "sandy"
    readonly property string displayName: "Sandy"
    readonly property string description: "Sun-washed sand with quiet mineral accents"
    readonly property bool dark: false
    readonly property color anchor: "#EECC92"

    readonly property color bg: "#F5E9D4"
    readonly property color bgAlt: "#EECC92"
    readonly property color bgRaised: "#FFF9EE"
    readonly property color bgOverlay: "#E8D8BB"

    // Dark mineral tones remain legible when used as text or icons on light
    // surfaces; the exact sandy anchor appears in fills and soft states.
    readonly property color accent: "#73572D"
    readonly property color accentAlt: "#42645B"
    readonly property color accentWarn: "#7A5015"
    readonly property color accentDanger: "#913F3F"
    readonly property color accentDangerSoft: "#38913F3F"
    readonly property color accentDangerSubtle: "#2B913F3F"
    readonly property color accentDangerHover: "#45913F3F"
    readonly property color accentPink: "#7F4F59"
    readonly property color accentCyan: "#3F666B"
    readonly property color accentPurple: "#5F4E74"
    readonly property color accentWood: "#73482D"
    readonly property color accentSoft: "#80EECC92"
    readonly property color accentWoodSoft: "#4DCE9A72"

    readonly property color fg: "#30271B"
    readonly property color fgDim: "#675B49"
    readonly property color fgFaint: "#6D604D"
    readonly property color fgDisabled: "#AA9B83"

    readonly property color borderSubtle: "#D8C6A5"
    readonly property color borderDefault: "#BDA77F"
    readonly property color borderStrong: "#89734D"

    readonly property color glassBg: "#F2FFF9EE"
    readonly property color glassBgStrong: "#FAFFF9EE"
    readonly property color glassBorder: "#A6A37F4F"
    readonly property color glassHover: "#5CEECC92"
    readonly property color glassActive: "#88EECC92"
    readonly property color surfaceHighlight: "#A6FFFFFF"
    readonly property color scrim: "#732F271C"
    readonly property color scrimSoft: "#522F271C"
    readonly property color viewportFill: "#4DEECC92"
    readonly property color shadowColor: "#332E2419"

    readonly property var groupColors: [
        "#42645B", "#913F3F", "#73572D", "#5F4E74",
        "#7A5015", "#3F666B", "#7F4F59"
    ]

    readonly property color wallpaperStart: "#FAF0DE"
    readonly property color wallpaperEnd: "#E8D1A8"
    readonly property color wallpaperGlowOne: "#8CEECC92"
    readonly property color wallpaperGlowTwo: "#4AD6B187"
    readonly property color wallpaperGlowThree: "#36809978"
    readonly property color wallpaperGlowFour: "#38FFF7E5"
    readonly property color wallpaperContour: "#14976F41"
    readonly property color wallpaperContourDeep: "#12604628"
    readonly property color wallpaperOverlay: "#12FFF2DC"

    readonly property real shadowSmOpacity: 0.14
    readonly property real shadowMdOpacity: 0.18
    readonly property real shadowLgOpacity: 0.24
}
