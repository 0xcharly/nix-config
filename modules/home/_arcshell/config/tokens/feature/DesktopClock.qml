import QtQuick
import Quickshell.Io
import qs.config
import qs.config.tokens.types

JsonObject {
    property bool blurBackground: true

    property int relativeX: 64
    property int relativeY: 48
    property int width: 512
    property int spacedBy: Config.tokens.system.measurements.none

    property TypographyValues dateTypography: Config.tokens.system.typography.title
    property TypographyValues timeTypography: Config.tokens.system.typography.headline

    property SurfaceColorValues colors: SurfaceColorValues {
        surface: Config.tokens.system.colors.surface_clock
        content: Config.tokens.system.colors.on_surface
    }
    property color dateContentColor: Config.tokens.system.colors.on_surface_variant

    property BorderValues borders: BorderValues {
        color: Config.tokens.system.colors.border_clock
        shape: Config.tokens.system.shapes.cornerSquare
        width: Config.tokens.system.measurements.twoExtraSmall
    }

    property PaddingValues padding: PaddingValues {
        bottom: Config.tokens.system.measurements.large
        left: Config.tokens.system.measurements.large
        right: Config.tokens.system.measurements.large
        top: Config.tokens.system.measurements.large
    }
}
