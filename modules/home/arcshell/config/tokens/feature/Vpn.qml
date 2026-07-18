import QtQuick
import Quickshell.Io
import qs.config
import qs.config.tokens.types

JsonObject {
    property bool enable: false

    // Glyph size: 80% of the standard bar icon size, rounded down.
    property int iconSize: Math.floor(Config.tokens.system.typography.icon.fontSize * 0.8)

    // Not egressing via Mullvad (and startup): zinc-grey like the
    // other bar icons.
    property SurfaceColorValues colors: SurfaceColorValues {
        surface: Config.tokens.system.colors.transparent
        content: Config.tokens.system.colors.on_surface_dim
    }
    // Egressing via a Mullvad exit node.
    property SurfaceColorValues connectedColors: SurfaceColorValues {
        surface: Config.tokens.system.colors.transparent
        content: Config.tokens.system.colors.on_surface_success
    }
    // The check itself failed.
    property SurfaceColorValues errorColors: SurfaceColorValues {
        surface: Config.tokens.system.colors.transparent
        content: Config.tokens.system.colors.on_surface_attention
    }
    // Same values as the volume slider label swap
    // (tokens/component/SliderLabel.qml).
    property AnimationValues animation: AnimationValues {
        duration: Config.tokens.system.animations.durations.small
        curveIn: Config.tokens.system.animations.curves.standardAccel
        curveOut: Config.tokens.system.animations.curves.standardDecel
    }
}
