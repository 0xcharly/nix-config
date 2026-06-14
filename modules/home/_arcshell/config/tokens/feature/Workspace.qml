import QtQuick
import Quickshell.Io
import qs.config
import qs.config.tokens.types

JsonObject {
    property SurfaceColorValues colors

    property int shape: Config.tokens.system.shapes.cornerSmall
    property TypographyValues typography: Config.tokens.system.typography.mediumLabel

    property PaddingValues padding: PaddingValues {
        bottom: Config.tokens.system.measurements.extraSmall
        left: Config.tokens.system.measurements.small
        right: Config.tokens.system.measurements.small
        top: Config.tokens.system.measurements.extraSmall
    }
}
