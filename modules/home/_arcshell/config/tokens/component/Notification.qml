import QtQuick
import Quickshell.Io
import qs.config
import qs.config.tokens.types

JsonObject {
    property int verticalSpacing: Config.tokens.system.measurements.medium
    property SurfaceTokens surface: Config.theme.defaults.cards

    property TypographyValues titleTypography: Config.tokens.system.typography.title
    property color titleContentColor: Config.tokens.system.colors.on_surface

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

    property AnimationValues animation: AnimationValues {}
}
