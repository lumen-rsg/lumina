pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common
Singleton {
    readonly property color bg: Appearance.m3colors.m3background
    readonly property color bgRaised: Appearance.m3colors.m3surfaceContainerLow
    readonly property color bgOverlay: Appearance.m3colors.m3surfaceContainerHigh
    readonly property color fg: Appearance.m3colors.m3onBackground
    readonly property color fgDim: Appearance.m3colors.m3onSurfaceVariant
    readonly property color fgFaint: Appearance.m3colors.m3outline
    readonly property color accent: Appearance.m3colors.m3primary
    readonly property color accentAlt: Appearance.m3colors.m3secondary
    readonly property color accentWarn: Appearance.m3colors.m3error
    readonly property color accentPurple: Appearance.m3colors.m3tertiary
    readonly property color accentCyan: Appearance.m3colors.m3secondary
    readonly property color accentWood: Appearance.m3colors.m3tertiary
    readonly property color borderDefault: Appearance.m3colors.m3outlineVariant
    readonly property color borderStrong: Appearance.m3colors.m3outline
    readonly property color borderSubtle: Appearance.m3colors.m3outlineVariant
    readonly property color glassBgStrong: Appearance.colors.colLayer0
    readonly property color glassBorder: Appearance.colors.colLayer0Border
    readonly property color glassHover: Appearance.colors.colLayer1Hover
    readonly property color glassActive: Appearance.colors.colLayer1Active
    readonly property color accentSoft: Appearance.m3colors.m3primaryContainer
    readonly property color scrim: "#99000000"
    readonly property color viewportFill: Qt.alpha(Appearance.m3colors.m3primary, 0.16)
    readonly property int radiusSm: 6
    readonly property int radius: 16
    readonly property int radiusLg: 24
    readonly property int barHeight: 58
    readonly property int fontSizeXs: 10
    readonly property int fontSizeSm: 12
    readonly property int fontSize: 13
    readonly property int fontSizeMd: 14
    readonly property int fontSizeLg: 20
    readonly property string fontFamily: Config.options.appearance.fonts.main
    readonly property string fontMono: Config.options.appearance.fonts.monospace
    readonly property int fontWeightBold: Font.DemiBold
    readonly property int fontWeightHeavy: Font.Bold
    readonly property int fontWeightMedium: Font.Medium
    readonly property int animFast: Config.options.appearance.reducedMotion ? 0 : 150
    readonly property int animNormal: Config.options.appearance.reducedMotion ? 0 : 250
    readonly property var groupColors: Appearance.palette ? Appearance.palette.groupColors : !Appearance.m3colors.darkmode ? ["#65558f", "#913f3f", "#42645b", "#5f4e74", "#7a5015", "#3f666b", "#7f4f59"] : ["#c3b8ff", "#ffb4ab", "#9bcfbe", "#b8c7ff", "#ebca89", "#9ccbd2", "#e7b8d0"]
}
