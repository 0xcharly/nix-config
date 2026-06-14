import QtQuick
import Quickshell.Io
import qs.config

JsonObject {
    property color color: Config.tokens.system.colors.surface
    property int shape: Config.tokens.system.shapes.cornerSquare
    property int width: Config.tokens.system.measurements.none
}
