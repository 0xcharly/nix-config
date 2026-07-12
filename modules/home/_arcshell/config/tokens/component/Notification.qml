import QtQuick
import Quickshell.Io
import qs.config
import qs.config.tokens.types

JsonObject {
    property int verticalSpacing: Config.tokens.system.measurements.small
    // Gap between the title and the timestamp on the first row.
    property int horizontalSpacing: Config.tokens.system.measurements.small
    // Dedicated surface (not theme.defaults.cards, which is shared with the
    // control center): full-bleed cards are square, so shape is 0.
    property SurfaceTokens surface: SurfaceTokens {
        colors: SurfaceColorValues {
            content: Config.tokens.system.colors.on_surface
            surface: Config.tokens.system.colors.surface_backdrop
        }
        padding: PaddingValues {
            bottom: Config.tokens.system.measurements.large
            left: Config.tokens.system.measurements.large
            right: Config.tokens.system.measurements.large
            top: Config.tokens.system.measurements.large
        }
        shape: 0
        typography: Config.tokens.system.typography.body
    }

    property TypographyValues titleTypography: Config.tokens.system.typography.smallTitle
    property color titleContentColor: Config.tokens.system.colors.on_surface

    property TypographyValues timestampTypography: Config.tokens.system.typography.mediumLabel
    property color timestampContentColor: Config.tokens.system.colors.on_surface_variant

    property int bodyMaxLines: 2

    property SurfaceColorValues colors: SurfaceColorValues {
        surface: Config.tokens.system.colors.transparent
        content: Config.tokens.system.colors.on_surface
    }

    property PaddingValues padding: PaddingValues {
        bottom: Config.tokens.system.measurements.large
        left: Config.tokens.system.measurements.large
        right: Config.tokens.system.measurements.large
        top: Config.tokens.system.measurements.large
    }

    // Reveal/dismiss motion: curveIn grows a row in (and springs a dragged
    // card back); curveOut slides a dismissed card off.
    property AnimationValues animation: AnimationValues {
        duration: Config.tokens.system.animations.durations.small
    }

    // Critical-urgency card surface. Only `surface` is consumed — the card
    // keeps the normal foreground colors; `content` is defined for
    // completeness only.
    property SurfaceColorValues surfaceCritical: SurfaceColorValues {
        surface: Config.tokens.system.colors.surface_danger
        content: Config.tokens.system.colors.on_surface_danger
    }
    // Vertical finger travel (px) that expands a collapsed card on drag-down.
    property int expandDragThreshold: 24
}
