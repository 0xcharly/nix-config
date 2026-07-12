import QtQuick
import Quickshell.Io
import qs.config
import qs.config.tokens.types

JsonObject {
    // Enabled by default: the widget additionally hides itself at runtime
    // when profile switching is unavailable (see hud/BarBottom.qml).
    property bool enable: true

    // Glyph size: 80% of the standard bar icon size, rounded down (same
    // as the VPN bar icon).
    property int iconSize: Math.floor(Config.tokens.system.typography.icon.fontSize * 0.8)

    property SurfaceColorValues colors: SurfaceColorValues {
        surface: Config.tokens.system.colors.transparent
        content: Config.tokens.system.colors.on_surface_dim
    }

    // Same values as the volume slider label swap
    // (tokens/component/SliderLabel.qml).
    property AnimationValues animation: AnimationValues {
        duration: Config.tokens.system.animations.durations.small
        curveIn: Config.tokens.system.animations.curves.standardAccel
        curveOut: Config.tokens.system.animations.curves.standardDecel
    }
}
