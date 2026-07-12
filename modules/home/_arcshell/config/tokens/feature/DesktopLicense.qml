import QtQuick
import Quickshell.Io
import qs.config
import qs.config.tokens.types

JsonObject {
    property int relativeX: 128
    property int relativeY: 128
    property int spacedBy: Config.tokens.system.measurements.small

    property TypographyValues titleTypography: Config.tokens.system.typography.largeTitle
    property TypographyValues bodyTypography: Config.tokens.system.typography.smallTitle

    property SurfaceColorValues colors: SurfaceColorValues {
        surface: Config.tokens.system.colors.transparent
        content: Config.tokens.system.colors.on_surface
    }
    property color bodyContentColor: Config.tokens.system.colors.on_surface_variant
}
