import QtQuick
import Quickshell.Io
import qs.config
import qs.config.tokens.types

JsonObject {
    property SurfaceColorValues colors: SurfaceColorValues {}
    property PaddingValues padding: PaddingValues {}
    property int shape: Config.tokens.system.shapes.cornerSquare
    property TypographyValues typography: Config.tokens.system.typography.body
}
