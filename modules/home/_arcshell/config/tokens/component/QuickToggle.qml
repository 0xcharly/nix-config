import QtQuick
import Quickshell.Io
import qs.config
import qs.config.tokens.types

JsonObject {
    property int verticalSpacing: Config.tokens.system.measurements.medium
    property TypographyValues typography: Config.tokens.system.typography.title
    property SurfaceTokens surface: Config.theme.defaults.cards
    property PaddingValues padding: PaddingValues {
        bottom: Config.tokens.system.measurements.medium
        left: Config.tokens.system.measurements.medium
        right: Config.tokens.system.measurements.medium
        top: Config.tokens.system.measurements.medium
    }

    property color trackColorRest: Config.tokens.system.colors.surface_control_track_rest
    property color trackColorChecked: Config.tokens.system.colors.surface_control_track_checked

    property SurfaceTokens icon: SurfaceTokens {
        colors: SurfaceColorValues {
            surface: Config.tokens.system.colors.surface_accent
            content: Config.tokens.system.colors.on_surface_accent
        }
        property PaddingValues padding: PaddingValues {
            bottom: Config.tokens.system.measurements.small
            left: Config.tokens.system.measurements.small
            right: Config.tokens.system.measurements.small
            top: Config.tokens.system.measurements.small
        }
        property int shape: Config.tokens.system.shapes.cornerFull
        property TypographyValues typography: Config.tokens.system.typography.icon
    }
    property SurfaceColorValues iconChecked: SurfaceColorValues {
        surface: Config.tokens.system.colors.surface_done
        content: Config.tokens.system.colors.on_surface_done
    }

    property AnimationValues animation: AnimationValues {}
}
