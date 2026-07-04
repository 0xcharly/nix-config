import QtQuick
import Quickshell.Io
import qs.config
import qs.config.tokens.types

JsonObject {
    property int verticalSpacing: Config.tokens.system.measurements.medium
    // Gap between the title and the timestamp on the first row.
    property int horizontalSpacing: Config.tokens.system.measurements.medium
    property SurfaceTokens surface: Config.theme.defaults.cards

    property TypographyValues titleTypography: Config.tokens.system.typography.title
    property color titleContentColor: Config.tokens.system.colors.on_surface

    property TypographyValues timestampTypography: Config.tokens.system.typography.mediumLabel
    property color timestampContentColor: Config.tokens.system.colors.on_surface_variant

    property int bodyMaxLines: 3

    property SurfaceColorValues colors: SurfaceColorValues {
        surface: Config.tokens.system.colors.transparent
        content: Config.tokens.system.colors.on_surface
    }

    property PaddingValues padding: PaddingValues {
        bottom: Config.tokens.system.measurements.medium
        left: Config.tokens.system.measurements.medium
        right: Config.tokens.system.measurements.medium
        top: Config.tokens.system.measurements.medium
    }

    // Reveal/dismiss motion: curveIn grows a row in (and springs a dragged
    // card back); curveOut slides a dismissed card off.
    property AnimationValues animation: AnimationValues {
        duration: Config.tokens.system.animations.durations.small
    }
}
