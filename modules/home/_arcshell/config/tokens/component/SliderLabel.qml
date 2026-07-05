import QtQuick
import Quickshell.Io
import qs.config
import qs.config.tokens.types

JsonObject {
    // Icon/text color; instances typically override to their slider's accent.
    property color color: Config.tokens.system.colors.on_surface
    // How long the value stays visible after the last change, ms.
    property int timeout: Config.tokens.system.animations.durations.threeExtraLarge
    property DotoTypographyValues typography: Config.tokens.system.typography.doto
    property AnimationValues animation: AnimationValues {
        duration: Config.tokens.system.animations.durations.small
        curveIn: Config.tokens.system.animations.curves.standardAccel
        curveOut: Config.tokens.system.animations.curves.standardDecel
    }
}
