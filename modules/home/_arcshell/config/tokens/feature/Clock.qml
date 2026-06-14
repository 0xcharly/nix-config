import QtQuick
import Quickshell.Io
import qs.config
import qs.config.tokens.types

JsonObject {
    property SurfaceColorValues colors: SurfaceColorValues {
        surface: Config.tokens.system.colors.transparent
        content: Config.tokens.system.colors.on_surface_variant
    }
    property PaddingValues padding: PaddingValues {
        bottom: Config.tokens.system.measurements.none
        left: Config.tokens.system.measurements.none
        right: Config.tokens.system.measurements.none
        top: Config.tokens.system.measurements.none
    }

    property int shape: Config.tokens.system.shapes.cornerSmall
    property int spacing: Config.tokens.system.measurements.small
    property TypographyValues typography: Config.tokens.system.typography.mediumLabel

    property SurfaceColorValues timeColors: SurfaceColorValues {
        surface: Config.tokens.system.colors.surface_backdrop
        content: Config.tokens.system.colors.on_surface_variant
    }
    property int timeShape: Config.tokens.system.shapes.cornerFull
    property PaddingValues timePadding: PaddingValues {
        bottom: Config.tokens.system.measurements.small
        left: Config.tokens.system.measurements.extraSmall
        right: Config.tokens.system.measurements.extraSmall
        top: Config.tokens.system.measurements.small
    }
}
