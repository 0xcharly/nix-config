import QtQuick
import Quickshell.Io
import qs.config
import qs.config.tokens.types

JsonObject {
    property int verticalSpacing: Config.tokens.system.measurements.medium
    property PaddingValues padding: PaddingValues {
        bottom: Config.tokens.system.measurements.small
        left: Config.tokens.system.measurements.small
        right: Config.tokens.system.measurements.small
        top: Config.tokens.system.measurements.small
    }
    property SurfaceTokens icon: SurfaceTokens {
        colors: SurfaceColorValues {
            surface: Config.tokens.system.colors.surface_accent
            content: Config.tokens.system.colors.on_surface_accent
        }
        padding: PaddingValues {
            bottom: Config.tokens.system.measurements.extraSmall
            left: Config.tokens.system.measurements.extraSmall
            right: Config.tokens.system.measurements.extraSmall
            top: Config.tokens.system.measurements.extraSmall
        }
        shape: Config.tokens.system.shapes.cornerFull
        typography: Config.tokens.system.typography.icon
    }
    property SurfaceColorValues iconChecked: SurfaceColorValues {
        surface: Config.tokens.system.colors.surface_done
        content: Config.tokens.system.colors.on_surface_done
    }
    property TypographyValues titleTypography: Config.tokens.system.typography.smallTitle
    property TypographyValues bodyTypography: Config.tokens.system.typography.body
    property color bodyContentColor: Config.tokens.system.colors.on_surface_variant
    property SurfaceTokens surface: Config.theme.defaults.cards
    property Switch switch_: Switch {}
    property SurfaceTokens activeChip: Config.theme.defaults.chips
    property AnimationValues activeChipAnimation: AnimationValues {
        curveIn: Config.tokens.system.animations.curves.expressiveDefaultSpatial
        curveOut: Config.tokens.system.animations.curves.expressiveDefaultSpatial
        duration: Config.tokens.system.animations.durations.expressiveDefaultSpatial
    }
}
