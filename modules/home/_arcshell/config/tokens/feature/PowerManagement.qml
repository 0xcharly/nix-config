import QtQuick
import Quickshell.Io
import qs.config
import qs.config.tokens.types

JsonObject {
    property bool enable: false

    property int spacedBy: Config.tokens.system.measurements.none
    property PowerManagementIcon icon: PowerManagementIcon {}

    property SurfaceColorValues colors: SurfaceColorValues {
        surface: Config.tokens.system.colors.transparent
        content: Config.tokens.system.colors.on_surface_dim
    }

    property TypographyValues typography: Config.tokens.system.typography.mediumLabel
    property PaddingValues padding: PaddingValues {
        bottom: Config.tokens.system.measurements.none
        left: Config.tokens.system.measurements.none
        right: Config.tokens.system.measurements.none
        top: Config.tokens.system.measurements.none
    }
}
